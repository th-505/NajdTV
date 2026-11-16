import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RemoteAction { playPause, forward, backward, fullscreen }

/// Only keys delivered to this app can be assigned; OS keys remain reserved.
class RemoteBindings extends ChangeNotifier {
  static final instance = RemoteBindings();
  static const storageKey = 'najd.remote.bindings.v1';
  final Map<int, RemoteAction> _keys = {};
  bool _loaded = false;
  static bool reserved(LogicalKeyboardKey key) =>
      {
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.browserHome,
        LogicalKeyboardKey.power,
        LogicalKeyboardKey.escape,
        LogicalKeyboardKey.goBack,
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.audioVolumeUp,
        LogicalKeyboardKey.audioVolumeDown,
        LogicalKeyboardKey.audioVolumeMute,
      }.contains(key) ||
      key.keyLabel.toLowerCase().contains('settings');
  static String label(RemoteAction action) => switch (action) {
    RemoteAction.playPause => 'تشغيل / إيقاف',
    RemoteAction.forward => 'تقديم الفيديو',
    RemoteAction.backward => 'ترجيع الفيديو',
    RemoteAction.fullscreen => 'ملء الشاشة',
  };
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = jsonDecode(prefs.getString(storageKey) ?? '{}');
      if (data is Map) {
        for (final entry in data.entries) {
          final id = int.tryParse('${entry.key}');
          final action = RemoteAction.values
              .where((a) => a.name == entry.value)
              .firstOrNull;
          if (id != null &&
              action != null &&
              !reserved(LogicalKeyboardKey(id))) {
            _keys[id] = action;
          }
        }
      }
    } catch (_) {
      /* Ignore malformed local preferences, never block playback. */
    }
    _loaded = true;
    notifyListeners();
  }

  RemoteAction? actionFor(LogicalKeyboardKey key) =>
      reserved(key) ? null : _keys[key.keyId];
  String keyFor(RemoteAction action) {
    final id = _keys.entries.where((e) => e.value == action).firstOrNull?.key;
    return id == null ? 'افتراضي' : LogicalKeyboardKey(id).keyLabel;
  }

  Future<void> assign(RemoteAction action, LogicalKeyboardKey key) async {
    if (reserved(key)) throw const FormatException('RESERVED_REMOTE_KEY');
    await load();
    _keys.removeWhere((_, value) => value == action);
    _keys[key.keyId] = action;
    await _save();
  }

  Future<void> reset() async {
    _keys.clear();
    _loaded = true;
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode({for (final e in _keys.entries) '${e.key}': e.value.name}),
    );
    notifyListeners();
  }
}

class RemoteBindingsPage extends StatefulWidget {
  const RemoteBindingsPage({super.key});
  @override
  State<RemoteBindingsPage> createState() => _RemoteBindingsPageState();
}

class _RemoteBindingsPageState extends State<RemoteBindingsPage> {
  final _focus = FocusNode();
  RemoteAction? _waiting;
  String? _message;
  @override
  void initState() {
    super.initState();
    RemoteBindings.instance.load();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تخصيص أزرار الريموت')),
    body: Focus(
      focusNode: _focus,
      onKeyEvent: (_, event) {
        final action = _waiting;
        if (action == null || event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (RemoteBindings.reserved(event.logicalKey)) {
          setState(() {
            _waiting = null;
            _message = 'هذا زر نظام محجوز ولا يمكن تخصيصه.';
          });
          return KeyEventResult.ignored;
        }
        RemoteBindings.instance.assign(action, event.logicalKey).then((_) {
          if (mounted) {
            setState(() {
              _waiting = null;
              _message = 'تم حفظ الزر لهذا الجهاز.';
            });
          }
        });
        return KeyEventResult.handled;
      },
      child: ListenableBuilder(
        listenable: RemoteBindings.instance,
        builder: (_, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'اختر وظيفة ثم اضغط زر الريموت. يعمل التخصيص داخل المشغل فقط. بعض أزرار النظام لا يرسلها المتصفح إلى الموقع.',
            ),
            if (_waiting != null)
              Text('اضغط الزر المطلوب: ${RemoteBindings.label(_waiting!)}'),
            if (_message != null) Text(_message!),
            for (final action in RemoteAction.values)
              ListTile(
                title: Text(RemoteBindings.label(action)),
                subtitle: Text(RemoteBindings.instance.keyFor(action)),
                trailing: const Icon(Icons.keyboard),
                onTap: () {
                  setState(() {
                    _waiting = action;
                    _message = null;
                  });
                  _focus.requestFocus();
                },
              ),
            TextButton(
              onPressed: () {
                setState(() => _waiting = null);
              },
              child: const Text('إلغاء تخصيص الزر'),
            ),
            TextButton(
              onPressed: RemoteBindings.instance.reset,
              child: const Text('استعادة الأزرار الافتراضية'),
            ),
          ],
        ),
      ),
    ),
  );
}
