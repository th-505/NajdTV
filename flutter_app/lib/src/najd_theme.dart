export 'splash_screen.dart';
import 'app_theme.dart';
import 'viewport_profile.dart';
import 'app_target.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NajdAppearance extends ChangeNotifier {
  static final instance = NajdAppearance();
  ThemeMode mode = ThemeMode.dark;
  String? fontFamily;
  bool bundledFontReady = false;
  bool bundledSerifReady = false;
  String get activeFontFamily =>
      bundledFontReady ? 'ThmanyahSans' : 'NajdArabicFallback';
  void markBundledFontReady({bool serif = false}) {
    bundledFontReady = true;
    bundledSerifReady = serif;
    notifyListeners();
  }

  void setFontFamily(String? value) {
    fontFamily = value;
    notifyListeners();
  }

  Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(
      'najd.theme.v1',
    );
    mode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.dark,
    );
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(
      'najd.theme.v1',
      value.name,
    );
  }
}

Future<bool> loadPrivateNajdFonts() async {
  final paths = [
    for (final weight in ['Regular', 'Medium', 'Bold'])
      'assets/najd/fonts/thmanyahsans-$weight.otf',
  ];
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().toSet();
    try {
      final declarations = jsonDecode(
        await rootBundle.loadString('FontManifest.json'),
      );
      if (declarations is List &&
          declarations.any(
            (entry) =>
                entry is Map &&
                entry['family'] == 'ThmanyahSans' &&
                entry['fonts'] is List &&
                (entry['fonts'] as List).every(
                  (face) => face is Map && bundled.contains(face['asset']),
                ),
          )) {
        final families = declarations
            .whereType<Map>()
            .map((entry) => entry['family'])
            .toSet();
        NajdAppearance.instance.markBundledFontReady(
          serif:
              families.contains('ThmanyahSerifText') &&
              families.contains('ThmanyahSerifDisplay'),
        );
        return true;
      }
    } catch (_) {
      /* Development/private imports may use runtime registration. */
    }
    if (!paths.every(bundled.contains)) return false;
    final loader = FontLoader('ThmanyahSans');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      loader.addFont(
        rootBundle.load('assets/najd/fonts/thmanyahsans-$weight.otf'),
      );
    }
    await loader.load();
    NajdAppearance.instance.markBundledFontReady();
    return true;
  } catch (_) {
    return false;
  } // No raw fonts are present in public source builds.
}

class NajdThemes {
  static TextTheme typography(TextTheme base) {
    final appearance = NajdAppearance.instance;
    if (!appearance.bundledSerifReady) {
      return base;
    }
    TextStyle? role(TextStyle? style, String family, FontWeight weight) =>
        style?.copyWith(fontFamily: family, fontWeight: weight);
    return base.copyWith(
      displayLarge: role(
        base.displayLarge,
        'ThmanyahSerifDisplay',
        FontWeight.w900,
      ),
      displayMedium: role(
        base.displayMedium,
        'ThmanyahSerifDisplay',
        FontWeight.w700,
      ),
      displaySmall: role(
        base.displaySmall,
        'ThmanyahSerifDisplay',
        FontWeight.w500,
      ),
      headlineLarge: role(
        base.headlineLarge,
        'ThmanyahSerifDisplay',
        FontWeight.w400,
      ),
      headlineMedium: role(
        base.headlineMedium,
        'ThmanyahSerifDisplay',
        FontWeight.w300,
      ),
      headlineSmall: role(
        base.headlineSmall,
        'ThmanyahSerifText',
        FontWeight.w900,
      ),
      titleLarge: role(base.titleLarge, 'ThmanyahSerifText', FontWeight.w700),
      titleMedium: role(base.titleMedium, 'ThmanyahSerifText', FontWeight.w500),
      titleSmall: role(base.titleSmall, 'ThmanyahSerifText', FontWeight.w300),
      bodyLarge: role(base.bodyLarge, 'ThmanyahSerifText', FontWeight.w400),
      bodyMedium: role(base.bodyMedium, 'ThmanyahSans', FontWeight.w400),
      bodySmall: role(base.bodySmall, 'ThmanyahSans', FontWeight.w300),
      labelLarge: role(base.labelLarge, 'ThmanyahSans', FontWeight.w700),
      labelMedium: role(base.labelMedium, 'ThmanyahSans', FontWeight.w500),
      labelSmall: role(base.labelSmall, 'ThmanyahSans', FontWeight.w900),
    );
  }

  static const lavender = NajdColors.darkPrimary;
  static ThemeData forBrightness(Brightness brightness, {bool? isTv}) {
    final dark = brightness == Brightness.dark;
    final background = dark
        ? NajdColors.darkBackground
        : NajdColors.lightBackground;
    final surface = dark ? NajdColors.darkSurface : Colors.white;
    final text = dark
        ? NajdColors.darkTextPrimary
        : NajdColors.lightTextPrimary;
    final secondary = dark
        ? NajdColors.darkTextSecondary
        : NajdColors.lightTextSecondary;
    final primary = dark ? NajdColors.darkPrimary : NajdColors.lightPrimary;
    final onPrimary = NajdContrast.onColor(primary);
    final glow = dark ? NajdColors.darkAccentGlow : NajdColors.lightAccentGlow;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: lavender,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          secondary: primary,
          surface: surface,
          onSurface: text,
          onSurfaceVariant: secondary,
          outline: dark ? const Color(0xFF3D3658) : const Color(0xFFDAD7EC),
        );
    return ThemeData(
      extensions: [
        NajdThemeExtension(
          surfaceGlass: dark
              ? NajdColors.darkSurfaceGlass
              : NajdColors.lightSurfaceGlass,
          surfaceElevated: dark
              ? NajdColors.darkSurfaceElevated
              : NajdColors.lightSurfaceElevated,
          accentGlow: glow,
          borderSubtle: dark ? NajdColors.darkBorder : NajdColors.lightBorder,
          serifFontFamily: NajdAppearance.instance.bundledSerifReady
              ? 'ThmanyahSerifDisplay'
              : 'NajdArabicFallback',
          sansFontFamily: NajdAppearance.instance.activeFontFamily,
          isTv: isTv ?? isTvTarget,
        ),
      ],
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: NajdAppearance.instance.activeFontFamily,
      fontFamilyFallback: const ['NajdArabicFallback'],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        centerTitle: true,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outline.withAlpha(90)),
        ),
        titleTextStyle: TextStyle(
          fontFamily: NajdAppearance.instance.activeFontFamily,
          fontFamilyFallback: const ['NajdArabicFallback'],
          color: text,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(
          fontFamily: NajdAppearance.instance.activeFontFamily,
          fontFamilyFallback: const ['NajdArabicFallback'],
          color: text,
          height: 1.7,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(48, (isTv ?? isTvTarget) ? 64 : 48),
          foregroundColor: dark ? glow : primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(48, (isTv ?? isTvTarget) ? 64 : 48),
          foregroundColor: dark ? glow : primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(isTvTarget ? 64 : 48, isTvTarget ? 64 : 48),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withAlpha(65),
        space: 24,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: primary.withAlpha(dark ? 100 : 40),
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textTheme: typography(
        ThemeData(brightness: brightness).textTheme.apply(
          fontFamily: NajdAppearance.instance.activeFontFamily,
          fontFamilyFallback: const ['NajdArabicFallback'],
          bodyColor: text,
          displayColor: text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: glow),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: Size(48, (isTv ?? isTvTarget) ? 64 : 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => primary.withAlpha(
            states.contains(WidgetState.dragged) ? 235 : 170,
          ),
        ),
        trackColor: WidgetStatePropertyAll(scheme.outline.withAlpha(65)),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(7),
        interactive: true,
      ),
      visualDensity: VisualDensity.standard,
    );
  }

  static ThemeData get dark => forBrightness(Brightness.dark);
  static ThemeData get light => forBrightness(Brightness.light);
}

class NajdThemeControl extends StatelessWidget {
  const NajdThemeControl({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: NajdAppearance.instance,
    builder: (context, _) => ListTile(
      leading: const Icon(Icons.contrast),
      title: const Text('مظهر نجد'),
      subtitle: const Text('فاتح · داكن'),
      trailing: DropdownButton<ThemeMode>(
        value: NajdAppearance.instance.mode == ThemeMode.light
            ? ThemeMode.light
            : ThemeMode.dark,
        items: const [
          DropdownMenuItem(value: ThemeMode.light, child: Text('فاتح')),
          DropdownMenuItem(value: ThemeMode.dark, child: Text('داكن')),
        ],
        onChanged: (value) {
          if (value != null) unawaited(NajdAppearance.instance.setMode(value));
        },
      ),
    ),
  );
}

abstract final class NajdTheme {
  static ThemeData light({required bool isTv}) =>
      NajdThemes.forBrightness(Brightness.light, isTv: isTv);
  static ThemeData dark({required bool isTv}) =>
      NajdThemes.forBrightness(Brightness.dark, isTv: isTv);
}

class NajdTvViewport extends StatefulWidget {
  const NajdTvViewport({super.key, required this.child});
  final Widget child;
  @override
  State<NajdTvViewport> createState() => _NajdTvViewportState();
}

class _NajdTvViewportState extends State<NajdTvViewport> {
  Map<String, Object>? _lastProfile;
  Future<void> _writes = Future<void>.value();
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final profile = NajdViewportProfile.measure(media);
    if (_lastProfile == null || !mapEquals(_lastProfile, profile)) {
      _lastProfile = profile;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(_lastProfile, profile)) return;
        // Serial writes prevent an older resize overwriting the latest metrics.
        // Failure to save diagnostics must never block layout or playback.
        _writes = _writes
            .then((_) => NajdViewportProfile.save(profile))
            .catchError((Object _) {});
      });
    }
    if (!isTvTarget) return widget.child;
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(
          media.textScaler.scale(1) * NajdViewportProfile.tvScale(media.size),
        ),
      ),
      child: widget.child,
    );
  }
}
