import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_library.dart';
import 'library_store.dart';
import 'quick_unlock.dart';

/// The SDK owns session storage. Passwords exist only in the form and request.
abstract interface class NajdAccountAuthentication {
  Future<bool> submit(String email, String password, {required bool create});
  Future<bool> verify(String email, String token);
  Future<bool> checkConfirmation();
}

class NajdEmailAuth implements NajdAccountAuthentication {
  NajdEmailAuth(this.client, this.store);
  final SupabaseClient client;
  final LocalLibraryStore? store;
  String displayName = "";
  static bool _changing = false;
  static const confirmationReturn =
      'https://th-505.github.io/NajdTV/auth-callback.html';
  OtpType verificationType = OtpType.signup;
  bool get signedIn => hasRegisteredNajdAccount(client);
  static bool validEmail(String value) =>
      value.length <= 254 &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  Future<bool> _change(Future<void> Function() action) async {
    if (_changing) throw StateError('ACCOUNT_CHANGE_BUSY');
    _changing = true;
    try {
      await CloudLibrarySync.closeDefault();
      await action();
      if (signedIn && store != null) {
        await CloudLibrarySync.bindAuthenticatedAccount(
          store!,
          client.auth.currentUser!.id,
        );
      }
      return signedIn;
    } finally {
      _changing = false;
      if (signedIn && store != null) {
        unawaited(CloudLibrarySync.startDefault(store!));
      }
    }
  }

  @override
  Future<bool> submit(
    String email,
    String password, {
    required bool create,
  }) async {
    email = email.trim();
    if (!validEmail(email) ||
        password.isEmpty ||
        password.length > 128 ||
        (create && password.length < 6)) {
      throw const FormatException('INVALID_ACCOUNT_INPUT');
    }
    if (create && signedIn) {
      throw const AuthException('SIGN_OUT_BEFORE_CREATING_ACCOUNT');
    }
    final ready = await _change(() async {
      if (create && client.auth.currentUser?.isAnonymous == true) {
        // Keep the existing owner and its library while upgrading a legacy account.
        verificationType = OtpType.emailChange;
        await client.auth.updateUser(
          UserAttributes(
            email: email,
            password: password,
            data: {if (displayName.isNotEmpty) 'display_name': displayName},
          ),
          emailRedirectTo: confirmationReturn,
        );
      } else if (create) {
        verificationType = OtpType.signup;
        await client.auth.signUp(
          email: email,
          password: password,
          data: {if (displayName.isNotEmpty) 'display_name': displayName},
          emailRedirectTo: confirmationReturn,
        );
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
      }
    });
    return ready &&
        client.auth.currentUser?.email?.toLowerCase() == email.toLowerCase();
  }

  @override
  Future<bool> verify(String email, String token) => _change(() async {
    if (!validEmail(email.trim()) ||
        !RegExp(r'^\d{6,10}$').hasMatch(token.trim())) {
      throw const FormatException('INVALID_CONFIRMATION');
    }
    await client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: verificationType,
    );
  });
  @override
  Future<bool> checkConfirmation() => _change(() async {
    if (client.auth.currentSession != null) await client.auth.refreshSession();
  });

  Future<void> signOut() async {
    final owner = client.auth.currentUser?.id;
    await _change(() async {
      await client.auth.signOut(scope: SignOutScope.local);
      if (owner != null) {
        try {
          await QuickUnlockService.instance.disable(owner);
        } catch (_) {}
      }
      if (store != null) await CloudLibrarySync.bindLocalGuest(store!);
    });
  }
}

class NajdEmailAuthPanel extends StatefulWidget {
  const NajdEmailAuthPanel({
    super.key,
    required this.auth,
    required this.onSignedIn,
  });
  final NajdAccountAuthentication auth;
  final VoidCallback onSignedIn;
  @override
  State<NajdEmailAuthPanel> createState() => _NajdEmailAuthPanelState();
}

class _NajdEmailAuthPanelState extends State<NajdEmailAuthPanel>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _verify && !_busy) {
      unawaited(_checkConfirmation());
    }
  }

  Future<void> _checkConfirmation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ready = await widget.auth.checkConfirmation();
      if (!mounted) return;
      if (ready) {
        widget.onSignedIn();
      } else {
        setState(
          () => _message = 'إن فتحت رابط التأكيد، اختر تسجيل الدخول أدناه. لا تحتاج رمزًا إلا إذا وصل في الرسالة.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'تعذّر فحص التأكيد. جرّب تسجيل الدخول بعد فتح رابط البريد.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController(),
      _token = TextEditingController();
  bool _create = false,
      _busy = false,
      _hide = true,
      _verify = false,
      _useCode = false;
  String _message = '';
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      if (_create && widget.auth is NajdEmailAuth) {
        (widget.auth as NajdEmailAuth).displayName = _name.text.trim();
      }
      final ready = _verify
          ? await widget.auth.verify(_email.text, _token.text)
          : await widget.auth.submit(
              _email.text,
              _password.text,
              create: _create,
            );
      if (!mounted) return;
      _password.clear();
      _confirm.clear();
      if (ready) {
        widget.onSignedIn();
      } else {
        setState(() {
          _verify = true;
          _message = 'راجع بريدك لتفعيل الحساب، ثم سجّل الدخول. ويمكنك إدخال رمز التأكيد هنا إن وصلك.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is AuthException && error.statusCode == '429'
              ? 'محاولات كثيرة؛ انتظر قليلًا ثم حاول مجددًا.'
              : 'تعذّر إتمام العملية. تحقق من البيانات وتفعيل البريد واتصال الإنترنت.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              Text(
                _verify
                    ? 'تأكيد بريد حساب نجد'
                    : _create
                    ? 'إنشاء حساب نجد'
                    : 'تسجيل الدخول إلى نجد',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'احفظ مكتبتك ومتابعة مشاهدتك بحسابك. التصفح المحلي لا ينشئ حسابًا تلقائيًا.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                enabled: !_busy && !_verify,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                ),
                validator: (value) =>
                    NajdEmailAuth.validEmail((value ?? '').trim())
                    ? null
                    : 'أدخل بريدًا إلكترونيًا صحيحًا',
              ),
              const SizedBox(height: 12),
              if (!_verify)
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  textDirection: TextDirection.ltr,
                  obscureText: _hide,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: [
                    _create
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    helperText: _create
                        ? '6 خانات على الأقل؛ يُفضل اختيار كلمة أطول'
                        : null,
                    suffixIcon: IconButton(
                      tooltip: _hide
                          ? 'إظهار كلمة المرور'
                          : 'إخفاء كلمة المرور',
                      onPressed: () => setState(() => _hide = !_hide),
                      icon: Icon(
                        _hide
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      value == null ||
                          value.isEmpty ||
                          value.length > 128 ||
                          (_create && value.length < 6)
                      ? 'تحقق من طول كلمة المرور'
                      : null,
                ),
              if (_create && !_verify) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  enabled: !_busy,
                  textDirection: TextDirection.ltr,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                  ),
                  validator: (value) => value == _password.text
                      ? null
                      : 'كلمتا المرور غير متطابقتين',
                ),
              ],
              if (_create && !_verify) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('account-display-name'),
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 64,
                  decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                  autofillHints: const [AutofillHints.nickname],
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'أدخل اسم المستخدم' : null,
                ),
              ],
              if (_verify) ...[
                const Text(
                  'افتح رابط التفعيل في بريدك، ثم عد واضغط الزر أدناه.',
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _useCode = !_useCode),
                  child: Text(
                    _useCode ? 'وصلني رابط تفعيل' : 'وصلني رمز بدل الرابط',
                  ),
                ),
                if (_useCode)
                  TextFormField(
                    controller: _token,
                    enabled: !_busy,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    decoration: const InputDecoration(
                      labelText: 'رمز تأكيد البريد',
                    ),
                    validator: (value) =>
                        RegExp(r'^\d{6,10}$').hasMatch((value ?? '').trim())
                        ? null
                        : 'أدخل رمز التأكيد',
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy
                    ? null
                    : (_verify && !_useCode ? _checkConfirmation : _submit),
                child: Text(
                  _busy
                      ? 'جارٍ التحقق…'
                      : _verify
                      ? (_useCode
                            ? 'تأكيد الرمز'
                            : 'فتحت رابط التفعيل — تحقق الآن')
                      : _create
                      ? 'إنشاء الحساب'
                      : 'تسجيل الدخول',
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _create = !_create;
                        _verify = false;
                        _useCode = false;
                        _message = '';
                        _password.clear();
                        _confirm.clear();
                      }),
                child: Text(
                  _create
                      ? 'لدي حساب — تسجيل الدخول'
                      : 'ليس لدي حساب — إنشاء حساب',
                ),
              ),
              if (_message.isNotEmpty)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_message),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
