#!/usr/bin/env python3
"""Generate deterministic Najd TV native, desktop and web branding after `flutter create`.

The approved Najd TV identity uses lavender surfaces and an original smooth Najdi emblem.
Private local font files are not published. Pillow is pinned in scripts/requirements-branding.txt.
"""
from __future__ import annotations

import io
import json
import plistlib
import re
import struct
import sys
import zlib
from pathlib import Path

# Safe optional import of PIL:
# The module can be safely imported and run in environments where Pillow is not yet installed.
try:
    from PIL import Image
except ImportError:
    Image = None

BACKGROUND = (8, 8, 14, 255)
ACCENT = (130, 128, 255, 255)
FOREGROUND = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)


def png_bytes(width: int, height: int, rgba: bytearray) -> bytes:
    """Generate valid PNG file bytes from raw RGBA buffer without external dependencies."""
    raw = b"".join(
        b"\x00" + bytes(rgba[y * width * 4 : (y + 1) * width * 4])
        for y in range(height)
    )

    def chunk(kind: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(kind + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", crc)

    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    idat_data = zlib.compress(raw, 9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr_data)
        + chunk(b"IDAT", idat_data)
        + chunk(b"IEND", b"")
    )


def mark(size: int, background: tuple[int, int, int, int]) -> bytes:
    """Package the original generated Najd master with antialiased icon scaling.

    Falls back to a valid pure-Python PNG if Pillow or the master image is not available.
    """
    dim = max(16, int(size))
    master = Path(__file__).resolve().parents[1] / "assets/brand/najd-mark.png"

    if Image is not None and master.exists():
        try:
            image = Image.open(master).convert("RGBA")
            bounds = image.getchannel("A").getbbox()
            if bounds:
                image = image.crop(bounds)

            canvas = Image.new("RGBA", (dim, dim), background)
            edge = max(12, round(canvas.width * 0.78))
            image.thumbnail((edge, edge), Image.Resampling.LANCZOS)

            offset = (
                (canvas.width - image.width) // 2,
                (canvas.height - image.height) // 2,
            )
            canvas.alpha_composite(image, offset)

            output = io.BytesIO()
            canvas.save(output, format="PNG", optimize=True)
            return output.getvalue()
        except Exception:
            pass

    # Pure-Python fallback when Pillow or the master image asset is unavailable
    bg_color = bytes(background)
    rgba = bytearray(bg_color * (dim * dim))
    return png_bytes(dim, dim, rgba)


def write_icon(path: Path, size: int, transparent: bool = False) -> None:
    """Write an icon of the specified size to the given path."""
    path.parent.mkdir(parents=True, exist_ok=True)
    bg = TRANSPARENT if transparent else BACKGROUND
    path.write_bytes(mark(size, bg))


def apply_android(root: Path) -> None:
    """Apply Najd TV branding, permissions, PiP, and network configuration to Android."""
    android = root / "android"
    if not android.exists():
        return

    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    res = android / "app/src/main/res"
    for folder, size in sizes.items():
        write_icon(res / folder / "ic_launcher.png", size)
    write_icon(res / "drawable" / "launch_mitv.png", 256, transparent=True)

    # Android's layer-list item `android:drawable` requires a drawable resource
    # reference. Keep the splash background in a named color resource rather than
    # embedding a raw #RRGGBB value, which fails aapt2 resource linking on API 21+.
    values = res / "values"
    values.mkdir(parents=True, exist_ok=True)
    colors_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="mitv_splash_bg">#07090b</color>\n'
        "</resources>\n"
    )
    (values / "colors.xml").write_text(colors_xml, encoding="utf-8")

    launch_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <item android:drawable="@color/mitv_splash_bg" />\n'
        '    <item><bitmap android:gravity="center" android:src="@drawable/launch_mitv" /></item>\n'
        "</layer-list>\n"
    )
    for folder in ("drawable", "drawable-v21"):
        target = res / folder / "launch_background.xml"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(launch_xml, encoding="utf-8")

    manifest = android / "app/src/main/AndroidManifest.xml"
    if manifest.exists():
        text = manifest.read_text(encoding="utf-8")

        # Flutter's debug/profile manifests grant Internet, but the generated
        # release manifest needs it explicitly for the API and direct HLS.
        permission = r'<uses-permission\b[^>]*android:name=["\']android\.permission\.INTERNET["\']'
        if not re.search(permission, text):
            text = re.sub(
                r'(<manifest\b[^>]*>)',
                r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>',
                text,
                count=1,
            )

        # Cleartext is limited to the device-local byte bridge; external media remains HTTPS.
        network = res / "xml/network_security_config.xml"
        network.parent.mkdir(parents=True, exist_ok=True)
        network.write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<network-security-config><base-config cleartextTrafficPermitted="false"/>\n'
            '<domain-config cleartextTrafficPermitted="true"><domain includeSubdomains="false">127.0.0.1</domain><domain includeSubdomains="false">localhost</domain></domain-config>\n'
            '</network-security-config>',
            encoding="utf-8",
        )

        if "android:networkSecurityConfig" not in text:
            text = re.sub(
                r"(<application\b)",
                r'\1 android:networkSecurityConfig="@xml/network_security_config"',
                text,
                count=1,
            )

        text = re.sub(r'android:label="[^"]*"', 'android:label="Najd TV"', text, count=1)

        activity = re.search(r'<activity\b[^>]*android:name="\.MainActivity"[^>]*>', text)
        if activity:
            tag = activity.group(0)
            for name in ("supportsPictureInPicture", "resizeableActivity"):
                key = "android:" + name
                if key + "=" in tag:
                    tag = re.sub(key + r'="[^"]*"', key + '="true"', tag)
                else:
                    tag = tag[:-1] + " " + key + '="true">'
            text = text.replace(activity.group(0), tag, 1)

        manifest.write_text(text, encoding="utf-8")

    # These tracked platform templates survive flutter create in hosted builds.
    source = Path(__file__).resolve().parents[1] / "flutter_app/native/android/MainActivity.kt"
    if source.exists():
        template_text = source.read_text(encoding="utf-8")
        for activity in (android / "app/src/main").rglob("MainActivity.kt"):
            package = re.search(r"^package\s+([\w.]+)", activity.read_text(encoding="utf-8"), re.M)
            if package:
                activity.write_text(
                    template_text.replace("__NAJD_PACKAGE__", package.group(1)),
                    encoding="utf-8",
                )


def ios_pixel_size(entry: dict) -> int:
    """Calculate pixel dimensions from iOS asset catalog size and scale specifiers."""
    raw_size = str(entry.get("size", "0x0")).split("x", 1)[0]
    scale = str(entry.get("scale", "1x")).rstrip("x")
    try:
        return max(16, round(float(raw_size) * float(scale)))
    except ValueError:
        return 64


def apply_ios(root: Path) -> None:
    """Apply Najd TV branding, audio background modes, and PiP to iOS."""
    ios = root / "ios"
    if not ios.exists():
        return

    assets = ios / "Runner/Assets.xcassets"
    contents = assets / "AppIcon.appiconset/Contents.json"
    if contents.exists():
        data = json.loads(contents.read_text(encoding="utf-8"))
        for image in data.get("images", []):
            filename = image.get("filename")
            if filename:
                write_icon(contents.parent / filename, ios_pixel_size(image))

    launch_contents = assets / "LaunchImage.imageset/Contents.json"
    if launch_contents.exists():
        data = json.loads(launch_contents.read_text(encoding="utf-8"))
        for image in data.get("images", []):
            filename = image.get("filename")
            if filename:
                scale = str(image.get("scale", "1x")).rstrip("x")
                try:
                    factor = max(1, int(float(scale)))
                except ValueError:
                    factor = 1
                write_icon(launch_contents.parent / filename, 192 * factor, transparent=True)

    storyboard = ios / "Runner/Base.lproj/LaunchScreen.storyboard"
    if storyboard.exists():
        text = storyboard.read_text(encoding="utf-8")
        text = text.replace(
            'red="1" green="1" blue="1" alpha="1"',
            'red="0.027" green="0.035" blue="0.043" alpha="1"',
        )
        text = text.replace(
            'red="0.035" green="0.035" blue="0.043" alpha="1"',
            'red="0.027" green="0.035" blue="0.043" alpha="1"',
        )
        storyboard.write_text(text, encoding="utf-8")

    plist = ios / "Runner/Info.plist"
    if plist.exists():
        with plist.open("rb") as fh:
            data = plistlib.load(fh)
        data.setdefault("NSAppTransportSecurity", {})["NSAllowsLocalNetworking"] = True
        data["CFBundleDisplayName"] = "Najd TV"
        data["CFBundleName"] = "Najd TV"
        data["UIFileSharingEnabled"] = True
        data["LSSupportsOpeningDocumentsInPlace"] = True
        data["UIBackgroundModes"] = sorted(set(data.get("UIBackgroundModes", [])) | {"audio"})
        with plist.open("wb") as fh:
            plistlib.dump(data, fh, sort_keys=False)

    delegate = ios / "Runner/AppDelegate.swift"
    if delegate.exists():
        source = Path(__file__).resolve().parents[1] / "flutter_app/native/ios/AppDelegate.swift"
        if source.exists():
            delegate.write_text(source.read_text(encoding="utf-8"), encoding="utf-8")


def apply_web(root: Path) -> None:
    """Generate web icons, favicon, and update web manifest metadata."""
    web = root / "web"
    if not web.exists():
        return

    for size in (192, 512):
        for name in (f"Icon-{size}.png", f"Icon-maskable-{size}.png"):
            write_icon(web / "icons" / name, size)
    write_icon(web / "favicon.png", 64)
    write_icon(web / "icons" / "Najd-Apple-180.png", 180)

    manifest = web / "manifest.json"
    if manifest.exists():
        data = json.loads(manifest.read_text(encoding="utf-8"))
        data.update({
            "name": "Najd TV",
            "short_name": "Najd TV",
            "background_color": "#08080e",
            "theme_color": "#08080e",
            "description": "Najd TV للأفلام والمسلسلات والأنمي والمباريات المباشرة",
        })
        manifest.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def apply_windows(root: Path) -> None:
    """Build multi-resolution Windows ICO and update native C++/RC project identity."""
    windows = root / "windows"
    if not windows.exists():
        return

    sizes = (16, 32, 48, 256)
    images = [(size, mark(size, BACKGROUND)) for size in sizes]

    # Windows ICO header: 3 words (reserved=0, type=1 for ICO, count=len(images))
    header = struct.pack("<HHH", 0, 1, len(images))
    offset = 6 + 16 * len(images)

    entries = []
    for size, data in images:
        entry_dim = 0 if size == 256 else size
        entries.append(
            struct.pack(
                "<BBBBHHII",
                entry_dim,
                entry_dim,
                0,
                0,
                1,
                32,
                len(data),
                offset,
            )
        )
        offset += len(data)

    icon = windows / "runner/resources/app_icon.ico"
    icon.parent.mkdir(parents=True, exist_ok=True)
    icon.write_bytes(header + b"".join(entries) + b"".join(data for _, data in images))

    main_cpp = windows / "runner/main.cpp"
    if main_cpp.exists():
        text = main_cpp.read_text(encoding="utf-8")
        text = re.sub(
            r'(?m)^([ \t]*if \(!window\.Create\().*?\)\)\s*\{',
            r'\1L"Najd TV", origin, size)) {',
            text,
            count=1,
        )
        main_cpp.write_text(text, encoding="utf-8")

    rc = windows / "runner/Runner.rc"
    if rc.exists():
        text = rc.read_text(encoding="utf-8")
        for key in ("CompanyName", "FileDescription", "ProductName"):
            pattern = r'(?m)^([ \t]*VALUE "' + re.escape(key) + r'", ).*$'
            text = re.sub(
                pattern,
                lambda match: match.group(1) + '"Najd TV" "\\0"',
                text,
            )
        rc.write_text(text, encoding="utf-8")


def apply_macos(root: Path) -> None:
    """Update macOS app name and sandbox entitlements."""
    macos = root / "macos"
    if not macos.exists():
        return

    plist = macos / "Runner/Info.plist"
    if plist.exists():
        with plist.open("rb") as fh:
            data = plistlib.load(fh)
        data["CFBundleDisplayName"] = "Najd TV"
        data["CFBundleName"] = "Najd TV"
        with plist.open("wb") as fh:
            plistlib.dump(data, fh, sort_keys=False)

    # The app is sandboxed but needs direct HTTPS playback/API access, the
    # device-local Alooy bridge, and user-selected subtitle files.
    entitlements = {
        "com.apple.security.app-sandbox": True,
        "com.apple.security.network.client": True,
        "com.apple.security.network.server": True,
        "com.apple.security.files.user-selected.read-only": True,
    }
    for name in ("DebugProfile.entitlements", "Release.entitlements"):
        path = macos / "Runner" / name
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("wb") as fh:
            plistlib.dump(entitlements, fh, sort_keys=False)


def main() -> None:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "flutter_app").resolve()
    apply_android(root)
    apply_ios(root)
    apply_windows(root)
    apply_macos(root)
    apply_web(root)
    print(f"native branding applied to {root}")


if __name__ == "__main__":
    main()
