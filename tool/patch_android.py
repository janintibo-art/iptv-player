#!/usr/bin/env python3
"""
Ajoute au manifeste Android genere par `flutter create` :
  - la permission INTERNET (absente du build release par defaut)
  - l autorisation du trafic HTTP non chiffre (beaucoup de flux sont en http://)
"""

import pathlib
import re
import sys

MANIFEST = pathlib.Path("android/app/src/main/AndroidManifest.xml")

if not MANIFEST.exists():
    sys.exit(f"Manifeste introuvable : {MANIFEST}")

xml = MANIFEST.read_text(encoding="utf-8")

if "android.permission.INTERNET" not in xml:
    xml = re.sub(
        r"(<manifest[^>]*>)",
        r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>'
        r'\n    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>'
        r'\n    <uses-permission android:name="android.permission.WAKE_LOCK"/>',
        xml,
        count=1,
    )
    print("Permissions ajoutees.")

if "usesCleartextTraffic" not in xml:
    xml = xml.replace(
        "<application",
        '<application\n        android:usesCleartextTraffic="true"',
        1,
    )
    print("Trafic HTTP autorise.")

MANIFEST.write_text(xml, encoding="utf-8")
print("Manifeste OK.")
