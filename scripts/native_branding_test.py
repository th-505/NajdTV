import importlib.util
import tempfile
from pathlib import Path

module_spec = importlib.util.spec_from_file_location('apply_native_branding', Path(__file__).with_name('apply_native_branding.py'))
branding = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(branding)

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    runner = root / 'windows' / 'runner'
    runner.mkdir(parents=True)
    (runner / 'main.cpp').write_text('  if (!window.Create(L"old title", origin, size)) {', encoding='utf-8')
    (runner / 'Runner.rc').write_text('\n'.join(
        f'VALUE "{key}", "old value" "\\0"' for key in ('CompanyName', 'FileDescription', 'ProductName')
    ), encoding='utf-8')
    branding.apply_windows(root)
    actual = (runner / 'Runner.rc').read_text(encoding='utf-8')
    assert actual.count('"Najd TV" "\\0"') == 3
    assert 'old value' not in actual
    assert (runner / 'main.cpp').read_text(encoding='utf-8') == '  if (!window.Create(L"Najd TV", origin, size)) {'
    first = actual
    branding.apply_windows(root)
    assert (runner / 'Runner.rc').read_text(encoding='utf-8') == first
print('native branding identity and Windows resource output are stable and idempotent')

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    native = root / 'android/app/src/main'
    activity = native / 'kotlin/com/mitv/mitv/MainActivity.kt'
    activity.parent.mkdir(parents=True)
    activity.write_text('package com.mitv.mitv\nclass MainActivity {}\n')
    manifest = native / 'AndroidManifest.xml'
    manifest.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application android:label="mitv"><activity android:name=".MainActivity" /></application></manifest>')
    branding.apply_android(root)
    assert 'android:supportsPictureInPicture="true"' in manifest.read_text()
    assert 'android:resizeableActivity="true"' in manifest.read_text()
    assert 'package com.mitv.mitv' in activity.read_text()
    assert '__NAJD_PACKAGE__' not in activity.read_text()
    assert 'enterPictureInPictureMode' in activity.read_text()
    first = manifest.read_text()
    branding.apply_android(root)
    assert manifest.read_text() == first
    runner = root / 'ios/Runner'
    runner.mkdir(parents=True)
    import plistlib
    (runner / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'com.mitv.mitv'}))
    (runner / 'AppDelegate.swift').write_text('import Flutter')
    branding.apply_ios(root)
    info = plistlib.loads((runner / 'Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == 'com.mitv.mitv'
    assert 'audio' in info['UIBackgroundModes']
    assert 'AVPictureInPictureController' in (runner / 'AppDelegate.swift').read_text()
print('Android and iOS packaging preserve compatibility identities and install OS PiP bridges')

# OS download permissions, secure backups and native XML survive repeat generation.
import xml.etree.ElementTree as ET
import plistlib
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    manifest = root / 'android/app/src/main/AndroidManifest.xml'
    manifest.parent.mkdir(parents=True)
    manifest.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application android:label="Najd TV"><activity android:name=".MainActivity" /></application></manifest>')
    branding.apply_android(root)
    branding.apply_android(root)
    xml = ET.parse(manifest).getroot()
    namespace = '{http://schemas.android.com/apk/res/android}'
    permissions = [p.attrib[namespace+'name'] for p in xml.findall('uses-permission')]
    assert len(permissions) == len(set(permissions))
    assert 'android.permission.FOREGROUND_SERVICE_DATA_SYNC' in permissions
    assert 'android.permission.POST_NOTIFICATIONS' in permissions
    app = xml.find('application')
    service = app.find('service')
    assert service.attrib[namespace+'foregroundServiceType'] == 'dataSync'
    assert app.attrib[namespace+'fullBackupContent'] == '@xml/najd_backup_rules'
    ET.parse(manifest.parent / 'res/xml/najd_backup_rules.xml')
    runner = root / 'ios/Runner'
    runner.mkdir(parents=True)
    (runner/'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'preserve.installed.identifier'}))
    (runner/'Runner.entitlements').write_bytes(plistlib.dumps({'aps-environment': 'development'}))
    project = root / 'ios/Runner.xcodeproj/project.pbxproj'
    project.parent.mkdir()
    project.write_text('buildSettings = { INFOPLIST_FILE = Runner/Info.plist; };')
    branding.apply_ios(root)
    branding.apply_ios(root)
    assert plistlib.loads((runner/'Info.plist').read_bytes())['CFBundleIdentifier'] == 'preserve.installed.identifier'
    entitlements = plistlib.loads((runner/'Runner.entitlements').read_bytes())
    assert entitlements['aps-environment'] == 'development'
    assert entitlements['keychain-access-groups'] == []
    assert project.read_text().count('CODE_SIGN_ENTITLEMENTS') == 1
print('native background permissions, app-local Keychain and backup configuration passed')
