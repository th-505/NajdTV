import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cloud_library.dart';
import 'cloud_runtime_stub.dart' if (dart.library.io) 'cloud_runtime_io.dart';
import 'email_auth.dart';
import 'library_store.dart';
import 'quick_unlock.dart';

class QuickUnlockSetupPage extends StatefulWidget {
  const QuickUnlockSetupPage({
    super.key,
    required this.authentication,
    required this.label,
  });
  final NajdEmailAuth authentication;
  final String label;
  @override
  State<QuickUnlockSetupPage> createState() => _QuickUnlockSetupPageState();
}

class _QuickUnlockSetupPageState extends State<QuickUnlockSetupPage> {
  final _password = TextEditingController(),
      _pin = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false, _enabled = false;
  String _message = '';
  String get _owner => widget.authentication.client.auth.currentUser?.id ?? '';
  @override
  void initState() {
    super.initState();
    QuickUnlockService.instance
        .enabledFor(_owner)
        .then((value) {
          if (mounted) setState(() => _enabled = value);
        })
        .catchError((_) {
          if (mounted) {
            setState(() => _message = 'تعذر فتح التخزين الآمن على هذا الجهاز.');
          }
        });
  }

  @override
  void dispose() {
    _password.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save({bool disable = false}) async {
    if (_busy) return;
    if (_password.text.isEmpty ||
        (!disable &&
            (!RegExp(r'^\d{4}$').hasMatch(_pin.text) ||
                _pin.text != _confirm.text))) {
      setState(
        () => _message = 'أدخل كلمة مرور حسابك ورمزًا متطابقًا من أربعة أرقام.',
      );
      return;
    }
    final owner = _owner,
        email = widget.authentication.client.auth.currentUser?.email ?? '';
    setState(() => _busy = true);
    try {
      if (!await widget.authentication.submit(
            email,
            _password.text,
            create: false,
          ) ||
          _owner != owner) {
        throw StateError('ACCOUNT_CHANGED');
      }
      if (disable) {
        await QuickUnlockService.instance.disable(owner);
      } else {
        await QuickUnlockService.instance.enroll(owner, _pin.text);
      }
      if (mounted) {
        setState(() {
          _enabled = !disable;
          _message = disable
              ? 'تم تعطيل الرمز السريع.'
              : 'تم تفعيل الرمز السريع لهذا الجهاز.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'تعذر حفظ الإعداد. تحقق من كلمة المرور واتصال الحساب والتخزين الآمن.',
        );
      }
    } finally {
      _password.clear();
      _pin.clear();
      _confirm.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('رمز الدخول السريع')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(widget.label),
        const Text(
          'رمز من أربعة أرقام لفتح هذا الجهاز بعد إعادة فتح نجد. الأجهزة الجديدة وتبديل الحساب يحتاجان تسجيل الدخول بالبريد وكلمة المرور.',
        ),
        TextField(
          controller: _password,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'كلمة مرور الحساب'),
        ),
        for (final (controller, label) in [
          (_pin, 'الرمز السريع'),
          (_confirm, 'تأكيد الرمز'),
        ])
          TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: label),
          ),
        if (_message.isNotEmpty) Text(_message),
        FilledButton(
          onPressed: _busy ? null : () => _save(),
          child: const Text('حفظ الرمز'),
        ),
        if (_enabled)
          TextButton(
            onPressed: _busy ? null : () => _save(disable: true),
            child: const Text('تعطيل الرمز السريع'),
          ),
        if (_busy) const LinearProgressIndicator(),
      ],
    ),
  );
}

/// Keeps the owned Navigator mounted but offstage until local unlock succeeds.
class DeviceUnlockGate extends StatefulWidget {
  const DeviceUnlockGate({
    super.key,
    required this.storeFuture,
    required this.child,
    this.authenticationForTesting,
    this.unlockService,
  });
  final Future<NajdEmailAuth> Function(LocalLibraryStore)?
  authenticationForTesting;
  final QuickUnlockService? unlockService;
  final Future<LocalLibraryStore> storeFuture;
  final Widget child;
  @override
  State<DeviceUnlockGate> createState() => _DeviceUnlockGateState();
}

class _DeviceUnlockGateState extends State<DeviceUnlockGate> {
  final _pin = TextEditingController();
  NajdEmailAuth? _authentication;
  String _owner = '', _label = '', _message = '';
  bool _loading = true, _locked = true, _busy = false, _password = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  QuickUnlockService get _unlockService =>
      widget.unlockService ?? QuickUnlockService.instance;

  Future<void> _load() async {
    // Widget tests use injected Auth, never production networking.
    if (widget.authenticationForTesting == null &&
        (cloudRuntimeIsTest || const bool.fromEnvironment('FLUTTER_TEST'))) {
      if (mounted) {
        setState(() {
          _loading = false;
          _locked = false;
        });
      }
      return;
    }
    try {
      final store = await widget.storeFuture;
      _authentication = widget.authenticationForTesting != null
          ? await widget.authenticationForTesting!(store)
          : NajdEmailAuth(await CloudLibrarySync.authenticationClient(), store);
      final client = _authentication!.client;
      if (!_authentication!.signedIn) {
        if (mounted) {
          setState(() {
            _loading = false;
            _locked = false;
          });
        }
        return;
      }
      _owner = client.auth.currentUser!.id;
      _label =
          '${client.auth.currentUser!.userMetadata?['display_name'] ?? client.auth.currentUser!.email ?? 'حساب نجد'}';
      final enabled = await _unlockService.enabledFor(_owner);
      if (mounted) {
        setState(() {
          _loading = false;
          _locked = enabled;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message =
              'تعذر التحقق من فتح الجهاز. أعد المحاولة أو سجّل الدخول بحسابك.';
        });
      }
    }
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _unlockService.verify(_owner, _pin.text);
      if (!mounted) return;
      setState(() {
        if (result == QuickUnlockResult.unlocked) {
          _locked = false;
        } else {
          _message = switch (result) {
            QuickUnlockResult.cooldown =>
              'انتظر ثلاثين ثانية قبل المحاولة مجددًا.',
            QuickUnlockResult.passwordRequired =>
              'سجّل الدخول بكلمة المرور لإعادة ضبط الرمز.',
            QuickUnlockResult.wrongAccount =>
              'هذا الرمز غير مفعّل للحساب الحالي.',
            _ => 'الرمز غير صحيح.',
          };
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'تعذر التحقق من الرمز. استخدم كلمة مرور الحساب.',
        );
      }
    } finally {
      _pin.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(
        offstage: _loading || _locked,
        child: ExcludeFocus(
          excluding: _loading || _locked,
          child: widget.child,
        ),
      ),
      if (_loading)
        const Scaffold(body: Center(child: CircularProgressIndicator()))
      else if (_locked)
        Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 48),
                      Text('مرحبًا $_label'),
                      if (_password && _authentication != null)
                        NajdEmailAuthPanel(
                          auth: _authentication!,
                          onSignedIn: () async {
                            final auth = _authentication!;
                            if (!auth.signedIn) return;
                            // Successful password authentication resets this device's old PIN.
                            try {
                              await _unlockService.disable(_owner);
                            } catch (_) {}
                            if (mounted) setState(() => _locked = false);
                          },
                        )
                      else ...[
                        TextField(
                          controller: _pin,
                          autofocus: true,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'رمز الدخول السريع',
                          ),
                          onSubmitted: (_) => _unlock(),
                        ),
                        FilledButton(
                          onPressed: _busy ? null : _unlock,
                          child: const Text('فتح نجد'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _password = true),
                          child: const Text('الدخول بالبريد وكلمة المرور'),
                        ),
                      ],
                      if (_message.isNotEmpty) Text(_message),
                      if (_authentication == null)
                        TextButton(
                          onPressed: _load,
                          child: const Text('أعد المحاولة'),
                        ),
                      if (_authentication != null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  try {
                                    await _authentication!.signOut();
                                    if (mounted) {
                                      setState(() => _locked = false);
                                    }
                                  } catch (_) {
                                    if (mounted) {
                                      setState(
                                        () => _message =
                                            'تعذر تسجيل الخروج. حاول مجددًا.',
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _busy = false);
                                  }
                                },
                          child: const Text('تسجيل الخروج والمتابعة محليًا'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
