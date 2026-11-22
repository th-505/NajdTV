#!/usr/bin/env python3
"""Generate deterministic Najd TV native, desktop and web branding after `flutter create`.

The approved Najd TV identity uses lavender surfaces and an original smooth Najdi emblem.
Private local font files are not published. Pillow is pinned in scripts/requirements-branding.txt.
"""
from __future__ import annotations

from PIL import Image
import io

import json
import plistlib
import re
import struct
import sys
import zlib
from pathlib import Path

BACKGROUND = (9, 7, 18, 255)
ACCENT = (130, 128, 255, 255)
FOREGROUND = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)


def png_bytes(width: int, height: int, rgba: bytearray) -> bytes:
    raw = b"".join(b"\x00" + bytes(rgba[y * width * 4:(y + 1) * width * 4]) for y in range(height))
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def mark(size: int, background: tuple[int, int, int, int], inset: bool = False) -> bytes:
    """Package the original generated Najd master with antialiased icon scaling."""
    master = Path(__file__).resolve().parents[1] / "assets/brand/najd-mark.png"
    image = Image.open(master).convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    if bounds:
        image = image.crop(bounds)
    canvas = Image.new("RGBA", (max(16, int(size)),) * 2, background)
    edge = max(12, round(canvas.width * .78)) if inset else canvas.width
    image.thumbnail((edge, edge), Image.Resampling.LANCZOS)
    canvas.alpha_composite(image, ((canvas.width-image.width)//2, (canvas.height-image.height)//2))
    output = io.BytesIO()
    canvas.save(output, format="PNG", optimize=True)
    return output.getvalue()


def write_icon(path: Path, size: int, transparent: bool = False, inset: bool = False):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(mark(size, TRANSPARENT if transparent else BACKGROUND, inset))


def apply_android(root: Path):
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
    logo = Path(__file__).resolve().parents[1] / "flutter_app/assets/images/najd_logo.png"
    with Image.open(logo) as image:
        image.resize((320, 180), Image.Resampling.LANCZOS).save(
            res / "drawable" / "najd_tv_banner.png", optimize=True
        )

    # Android's layer-list item `android:drawable` requires a drawable resource
    # reference. Keep the splash background in a named color resource rather than
    # embedding a raw #RRGGBB value, which fails aapt2 resource linking on API 21+.
    values = res / "values"
    values.mkdir(parents=True, exist_ok=True)
    (values / "colors.xml").write_text(
        """<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>\n    <color name=\"mitv_splash_bg\">#07090b</color>\n</resources>\n""",
        encoding="utf-8",
    )
    launch_xml = """<?xml version=\"1.0\" encoding=\"utf-8\"?>
<layer-list xmlns:android=\"http://schemas.android.com/apk/res/android\">
    <item android:drawable=\"@color/mitv_splash_bg\" />
    <item><bitmap android:gravity=\"center\" android:src=\"@drawable/launch_mitv\" /></item>
</layer-list>
"""
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
            text = re.sub(r'(<manifest\b[^>]*>)', r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>', text, count=1)
        # Android's OS transfer worker needs foreground data-sync and user notifications.
        for name in ("POST_NOTIFICATIONS", "FOREGROUND_SERVICE", "FOREGROUND_SERVICE_DATA_SYNC", "RUN_USER_INITIATED_JOBS", "ACCESS_NETWORK_STATE", "WAKE_LOCK"):
            if 'android.permission.' + name + '"' not in text:
                text = re.sub(r'(<manifest\b[^>]*>)', r'\1\n    <uses-permission android:name="android.permission.' + name + '"/>', text, count=1)
        if "androidx.work.impl.foreground.SystemForegroundService" not in text:
            text = text.replace("</application>", '<service android:name="androidx.work.impl.foreground.SystemForegroundService" android:foregroundServiceType="dataSync"/>' + "</application>")
        # Cleartext is limited to the device-local byte bridge; external media remains HTTPS.
        network = res / "xml/network_security_config.xml"
        network.parent.mkdir(parents=True, exist_ok=True)
        network.write_text('''<?xml version="1.0" encoding="utf-8"?>
<network-security-config><base-config cleartextTrafficPermitted="false"/>
<domain-config cleartextTrafficPermitted="true"><domain includeSubdomains="false">127.0.0.1</domain><domain includeSubdomains="false">localhost</domain></domain-config>
</network-security-config>''', encoding="utf-8")
        text = re.sub(r'(<application\b)', r'\1 android:networkSecurityConfig="@xml/network_security_config"', text, count=1) if 'android:networkSecurityConfig' not in text else text
        text = re.sub(r'android:label="[^"]*"', 'android:label="Najd TV"', text, count=1)
        activity = re.search(r'<activity\b[^>]*android:name="\.MainActivity"[^>]*>', text)
        if activity:
            tag = activity.group(0)
            for name in ('supportsPictureInPicture', 'resizeableActivity'):
                key = 'android:' + name
                if key + '=' in tag:
                    tag = re.sub(key + r'="[^"]*"', key + '="true"', tag)
                else:
                    closing = '/>' if tag.rstrip().endswith('/>') else '>'
                    tag = tag.rstrip()[:-len(closing)].rstrip() + ' ' + key + '="true"' + closing
            text = text.replace(activity.group(0), tag, 1)
        # Device unlock secrets must never migrate through Android cloud/device backup.
        backup = res / "xml/najd_backup_rules.xml"
        backup.write_text('<full-backup-content><exclude domain="sharedpref" path="FlutterSecureStorage.xml"/><exclude domain="sharedpref" path="FlutterSecureKeyStorage.xml"/></full-backup-content>', encoding="utf-8")
        extraction = res / "xml/najd_data_extraction_rules.xml"
        excluded = '<exclude domain="sharedpref" path="FlutterSecureStorage.xml"/><exclude domain="sharedpref" path="FlutterSecureKeyStorage.xml"/>'
        extraction.write_text('<data-extraction-rules><cloud-backup>' + excluded + '</cloud-backup><device-transfer>' + excluded + '</device-transfer></data-extraction-rules>', encoding="utf-8")
        for attribute, value in (("fullBackupContent", "@xml/najd_backup_rules"), ("dataExtractionRules", "@xml/najd_data_extraction_rules")):
            key = "android:" + attribute
            if key + '=' in text:
                text = re.sub(key + r'="[^"]*"', key + '="' + value + '"', text, count=1)
            else:
                text = re.sub(r'(<application\b)', r'\1 ' + key + '="' + value + '"', text, count=1)
        manifest.write_text(text, encoding="utf-8")
    # These tracked platform templates survive flutter create in hosted builds.
    source = Path(__file__).resolve().parents[1] / 'flutter_app/native/android/MainActivity.kt'
    for activity in (android / 'app/src/main').rglob('MainActivity.kt'):
        package = re.search(r'^package\s+([\w.]+)', activity.read_text(), re.M)
        if package:
            activity.write_text(source.read_text().replace('__NAJD_PACKAGE__', package.group(1)))


def ios_pixel_size(entry: dict) -> int:
    raw_size = str(entry.get("size", "0x0")).split("x", 1)[0]
    scale = str(entry.get("scale", "1x")).rstrip("x")
    try:
        return max(16, round(float(raw_size) * float(scale)))
    except ValueError:
        return 64


def apply_ios(root: Path):
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
                try: factor = max(1, int(float(scale)))
                except ValueError: factor = 1
                write_icon(launch_contents.parent / filename, 192 * factor, transparent=True)
    storyboard = ios / "Runner/Base.lproj/LaunchScreen.storyboard"
    if storyboard.exists():
        text = storyboard.read_text(encoding="utf-8")
        text = text.replace('red="1" green="1" blue="1" alpha="1"', 'red="0.027" green="0.035" blue="0.043" alpha="1"')
        text = text.replace('red="0.035" green="0.035" blue="0.043" alpha="1"', 'red="0.027" green="0.035" blue="0.043" alpha="1"')
        storyboard.write_text(text, encoding="utf-8")
    plist = ios / "Runner/Info.plist"
    if plist.exists():
        with plist.open("rb") as fh:
            data = plistlib.load(fh)
        data.setdefault("NSAppTransportSecurity", {})["NSAllowsLocalNetworking"] = True
        data["CFBundleDisplayName"] = "Najd TV"
        data["CFBundleName"] = "Najd TV"
        data["NSPhotoLibraryAddUsageDescription"] = "حفظ فيديو تختاره في مكتبة الصور عند تصديره."
        data["NSPhotoLibraryUsageDescription"] = "الوصول إلى فيديو تختاره من مكتبة الصور عند تصديره."
        data["UIFileSharingEnabled"] = True
        data["LSSupportsOpeningDocumentsInPlace"] = True
        data["UIBackgroundModes"] = sorted(set(data.get("UIBackgroundModes", [])) | {"audio"})
        with plist.open("wb") as fh:
            plistlib.dump(data, fh, sort_keys=False)


    # The PIN verifier is local to this app's Keychain; no shared App Group.
    entitlements = ios / "Runner/Runner.entitlements"
    if entitlements.parent.exists():
        existing = plistlib.loads(entitlements.read_bytes()) if entitlements.exists() else {}
        existing.setdefault("keychain-access-groups", [])
        entitlements.write_bytes(plistlib.dumps(existing))
    project = ios / "Runner.xcodeproj/project.pbxproj"
    if project.exists():
        def keychain_settings(match):
            block = match.group(0)
            if "INFOPLIST_FILE = Runner/Info.plist;" in block and "CODE_SIGN_ENTITLEMENTS" not in block:
                block = block.replace("INFOPLIST_FILE = Runner/Info.plist;", "INFOPLIST_FILE = Runner/Info.plist;\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;")
            return block
        project.write_text(re.sub(r"buildSettings = \{[^{}]*\};", keychain_settings, project.read_text()), encoding="utf-8")

    delegate = ios / "Runner/AppDelegate.swift"
    if delegate.exists():
        source = Path(__file__).resolve().parents[1] / 'flutter_app/native/ios/AppDelegate.swift'
        delegate.write_text(source.read_text())


def apply_web(root: Path):
    web=root / "web"
    if not web.exists(): return
    for size in (192,512):
        for name in (f"Icon-{size}.png",f"Icon-maskable-{size}.png"):
            write_icon(web/"icons"/name, size, inset="maskable" in name)
    write_icon(web/"favicon.png",64)
    write_icon(web/"icons"/"Najd-Apple-180.png",180)
    manifest = web / "manifest.json"
    if manifest.exists():
        data = json.loads(manifest.read_text(encoding="utf-8"))
        data.update({
            "background_color": "#090712",
            "theme_color": "#090712",
            "description": "Najd TV للأفلام والمسلسلات والأنمي والمباريات المباشرة",
        })
        manifest.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def apply_windows(root: Path):
    windows=root/"windows"
    if not windows.exists(): return
    images=[(size,mark(size,BACKGROUND)) for size in (16,32,48,256)]
    header=struct.pack('<HHH',0,1,len(images)); offset=6+16*len(images)
    entries=[]
    for size,data in images:
        entries.append(struct.pack('<BBBBHHII',0 if size==256 else size,0 if size==256 else size,0,0,1,32,len(data),offset));offset+=len(data)
    icon=windows/'runner/resources/app_icon.ico';icon.parent.mkdir(parents=True,exist_ok=True)
    icon.write_bytes(header+b''.join(entries)+b''.join(data for _,data in images))
    main=windows/'runner/main.cpp'
    if main.exists():
        text=main.read_text()
        text=re.sub(r'(?m)^([ \t]*if \(!window\.Create\().*?\)\)\s*\{',r'\1L"Najd TV", origin, size)) {',text,count=1)
        main.write_text(text)
    rc=windows/'runner/Runner.rc'
    if rc.exists():
        text=rc.read_text()
        for key in ('CompanyName','FileDescription','ProductName'):
            pattern=r'(?m)^([ \t]*VALUE "'+re.escape(key)+r'", ).*$'
            text=re.sub(pattern,lambda match: match.group(1)+'"Najd TV" "\\0"',text)
        rc.write_text(text)


def apply_macos(root: Path):
    macos = root / "macos"
    if not macos.exists():
        return
    icons = macos / "Runner/Assets.xcassets/AppIcon.appiconset"
    contents = icons / "Contents.json"
    if contents.exists():
        for entry in json.loads(contents.read_text(encoding="utf-8")).get("images", []):
            if filename := entry.get("filename"):
                write_icon(icons / filename, ios_pixel_size(entry))
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


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "flutter_app").resolve()
    apply_android(root)
    apply_ios(root)
    apply_windows(root)
    apply_macos(root)
    apply_web(root)
    print(f"native branding applied to {root}")


if __name__ == "__main__":
    main()
