import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class QuickUnlockVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SystemQuickUnlockVault implements QuickUnlockVault {
  static const _key = 'najd.device-unlock.v1';
  final _storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// PBKDF2-HMAC-SHA256; a PIN unlocks this device, never a Supabase identity.
String deriveDevicePin(Map<String, String> values) {
  final mac = Hmac(sha256, utf8.encode(values['pin']!));
  var u = mac.convert([
    ...utf8.encode('${values['owner']}\u0000${values['salt']}'),
    0,
    0,
    0,
    1,
  ]).bytes;
  final output = List<int>.of(u);
  for (var i = 1; i < 100000; i++) {
    u = mac.convert(u).bytes;
    for (var j = 0; j < output.length; j++) {
      output[j] ^= u[j];
    }
  }
  return output.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

enum QuickUnlockResult {
  unlocked,
  incorrect,
  cooldown,
  passwordRequired,
  wrongAccount,
}

class QuickUnlockService {
  QuickUnlockService({
    QuickUnlockVault? vault,
    DateTime Function()? now,
    Future<String> Function(Map<String, String>)? derive,
  }) : _vault = vault ?? SystemQuickUnlockVault(),
       _now = now ?? DateTime.now,
       _derive = derive ?? ((input) => compute(deriveDevicePin, input));
  static final instance = QuickUnlockService();
  final QuickUnlockVault _vault;
  final DateTime Function() _now;
  final Future<String> Function(Map<String, String>) _derive;
  bool _busy = false;
  Future<T> _serial<T>(Future<T> Function() action) async {
    if (_busy) throw StateError('DEVICE_UNLOCK_BUSY');
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  Future<Map<String, dynamic>?> _read() async {
    final raw = await _vault.read();
    if (raw == null) return null;
    if (raw.length > 2048) throw const FormatException('INVALID_DEVICE_UNLOCK');
    final data = jsonDecode(raw);
    if (data is! Map ||
        data['v'] != 1 ||
        data['owner'] is! String ||
        !RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
        ).hasMatch(data['owner']) ||
        data['salt'] is! String ||
        data['salt'].length != 44 ||
        data['digest'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(data['digest']) ||
        data['failures'] is! int ||
        data['blocked_until'] is! int ||
        data['last_attempt'] is! int ||
        data['failures'] < 0 ||
        data['failures'] > 10 ||
        data['blocked_until'] < 0 ||
        data['last_attempt'] < 0) {
      throw const FormatException('INVALID_DEVICE_UNLOCK');
    }
    return data.cast<String, dynamic>();
  }

  Future<bool> enabledFor(String owner) async =>
      (await _read())?['owner'] == owner;
  Future<void> enroll(String owner, String pin) => _serial(() async {
    if (!RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
        ).hasMatch(owner) ||
        !RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const FormatException('INVALID_DEVICE_PIN');
    }
    final random = Random.secure();
    final salt = base64Encode(List.generate(32, (_) => random.nextInt(256)));
    final digest = await _derive({'owner': owner, 'pin': pin, 'salt': salt});
    await _vault.write(
      jsonEncode({
        'v': 1,
        'owner': owner,
        'salt': salt,
        'digest': digest,
        'failures': 0,
        'blocked_until': 0,
        'last_attempt': 0,
      }),
    );
  });
  Future<QuickUnlockResult> verify(String owner, String pin) => _serial(
    () async {
      final data = await _read();
      if (data == null || data['owner'] != owner) {
        return QuickUnlockResult.wrongAccount;
      }
      if (data['failures'] >= 10) return QuickUnlockResult.passwordRequired;
      final now = _now().millisecondsSinceEpoch;
      if (now < data['last_attempt']) return QuickUnlockResult.passwordRequired;
      if (now < data['blocked_until']) return QuickUnlockResult.cooldown;
      // Persist before hashing so terminating the app cannot reset attempts.
      data['failures'] = (data['failures'] as int) + 1;
      data['last_attempt'] = now;
      if (data['failures'] >= 5) data['blocked_until'] = now + 30000;
      await _vault.write(jsonEncode(data));
      final candidate = RegExp(r'^\d{4}$').hasMatch(pin)
          ? await _derive({'owner': owner, 'pin': pin, 'salt': data['salt']})
          : '';
      final expected = data['digest'] as String;
      var diff = candidate.length ^ expected.length;
      for (var i = 0; i < expected.length; i++) {
        diff |=
            expected.codeUnitAt(i) ^
            (i < candidate.length ? candidate.codeUnitAt(i) : 0);
      }
      if (diff != 0) {
        return data['failures'] >= 10
            ? QuickUnlockResult.passwordRequired
            : QuickUnlockResult.incorrect;
      }
      data['failures'] = 0;
      data['blocked_until'] = 0;
      await _vault.write(jsonEncode(data));
      return QuickUnlockResult.unlocked;
    },
  );
  Future<void> disable(String owner) => _serial(() async {
    if ((await _read())?['owner'] == owner) await _vault.clear();
  });
}
