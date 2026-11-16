import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mitv/src/remote_bindings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'remote assignments preserve reserved system keys and one action per key',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = RemoteBindings();
      await prefs.assign(RemoteAction.playPause, LogicalKeyboardKey.keyP);
      expect(prefs.actionFor(LogicalKeyboardKey.keyP), RemoteAction.playPause);
      await prefs.assign(RemoteAction.forward, LogicalKeyboardKey.keyP);
      expect(prefs.actionFor(LogicalKeyboardKey.keyP), RemoteAction.forward);
      expect(prefs.keyFor(RemoteAction.playPause), 'افتراضي');
      final restored = RemoteBindings();
      await restored.load();
      expect(restored.actionFor(LogicalKeyboardKey.keyP), RemoteAction.forward);
      for (final key in [
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.browserHome,
        LogicalKeyboardKey.power,
        LogicalKeyboardKey.escape,
        LogicalKeyboardKey.audioVolumeUp,
      ]) {
        await expectLater(
          prefs.assign(RemoteAction.playPause, key),
          throwsFormatException,
        );
        expect(prefs.actionFor(key), isNull);
      }
      await prefs.reset();
      expect(prefs.actionFor(LogicalKeyboardKey.keyP), isNull);
    },
  );
}
