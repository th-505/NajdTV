import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/quick_unlock.dart';

class MemoryVault implements QuickUnlockVault {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String input) async {
    value = input;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

const owner = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
Future<String> fastHash(Map<String, String> input) async =>
    sha256.convert(utf8.encode(jsonEncode(input))).toString();
void main() {
  test('PBKDF2 agrees with independent hashlib vector', () {
    expect(
      deriveDevicePin({'owner': owner, 'pin': '1234', 'salt': 'test-salt'}),
      '4e95d04abbd1663b699444aacbeff978c07e91087919494019555ddbc6e40665',
    );
  });
  test('verifier is salted, account-bound and never stores PIN', () async {
    final vault = MemoryVault();
    final service = QuickUnlockService(vault: vault, derive: fastHash);
    await service.enroll(owner, '9826');
    expect(vault.value, isNot(contains('9826')));
    expect(await service.enabledFor(owner), isTrue);
    expect(await service.verify(other, '9826'), QuickUnlockResult.wrongAccount);
    expect(await service.verify(owner, '9826'), QuickUnlockResult.unlocked);
    final first = jsonDecode(vault.value!)['digest'];
    await service.enroll(owner, '9826');
    expect(jsonDecode(vault.value!)['digest'], isNot(first));
    await service.disable(other);
    expect(await service.enabledFor(owner), isTrue);
    await service.disable(owner);
    expect(await service.verify(owner, '9826'), QuickUnlockResult.wrongAccount);
  });
  test('persistent cooldown and password recovery survive restart', () async {
    final vault = MemoryVault();
    var clock = DateTime.utc(2026);
    QuickUnlockService fresh() =>
        QuickUnlockService(vault: vault, derive: fastHash, now: () => clock);
    await fresh().enroll(owner, '1234');
    for (var i = 0; i < 5; i++) {
      expect(await fresh().verify(owner, '0000'), QuickUnlockResult.incorrect);
    }
    expect(await fresh().verify(owner, '1234'), QuickUnlockResult.cooldown);
    for (var i = 5; i < 10; i++) {
      clock = clock.add(const Duration(seconds: 31));
      expect(
        await fresh().verify(owner, '0000'),
        i == 9
            ? QuickUnlockResult.passwordRequired
            : QuickUnlockResult.incorrect,
      );
    }
    clock = clock.add(const Duration(days: 1));
    expect(
      await fresh().verify(owner, '1234'),
      QuickUnlockResult.passwordRequired,
    );
  });
  test('clock rollback cannot bypass attempts', () async {
    final vault = MemoryVault();
    var clock = DateTime.utc(2026);
    final service = QuickUnlockService(
      vault: vault,
      derive: fastHash,
      now: () => clock,
    );
    await service.enroll(owner, '1234');
    await service.verify(owner, '0000');
    clock = clock.subtract(const Duration(seconds: 1));
    expect(
      await service.verify(owner, '1234'),
      QuickUnlockResult.passwordRequired,
    );
  });
  test('rejects malformed and negative persisted state', () async {
    final vault = MemoryVault();
    final service = QuickUnlockService(vault: vault, derive: fastHash);
    await expectLater(service.enroll(owner, '123'), throwsFormatException);
    await expectLater(service.enroll('-' * 36, '1234'), throwsFormatException);
    await service.enroll(owner, '1234');
    final data = jsonDecode(vault.value!);
    data['failures'] = -1;
    vault.value = jsonEncode(data);
    await expectLater(service.verify(owner, '1234'), throwsFormatException);
  });
  test('parallel attempts cannot overwrite failure count', () async {
    final vault = MemoryVault();
    final ready = Completer<String>();
    final service = QuickUnlockService(vault: vault, derive: fastHash);
    await service.enroll(owner, '1234');
    final slow = QuickUnlockService(vault: vault, derive: (_) => ready.future);
    final first = slow.verify(owner, '0000');
    await Future<void>.delayed(Duration.zero);
    await expectLater(slow.verify(owner, '0000'), throwsStateError);
    expect(jsonDecode(vault.value!)['failures'], 1);
    ready.complete('0' * 64);
    expect(await first, QuickUnlockResult.incorrect);
  });
}
