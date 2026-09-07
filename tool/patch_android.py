#!/usr/bin/env python3
"""
Adapte le projet Android genere par `flutter create` :

  1. permission INTERNET (absente du build release par defaut)
  2. trafic HTTP non chiffre (beaucoup de flux sont en http://)
  3. support Android TV : leanback, ecran sans tactile, banniere
  4. support du picture-in-picture, via un MainActivity maison

Aucun plugin tiers n est utilise : le pont PiP tient en quelques lignes
de Kotlin injectees dans l activite principale.
"""

import pathlib
import re
import shutil
import sys

RACINE = pathlib.Path('android/app/src/main')
MANIFEST = RACINE / 'AndroidManifest.xml'

if not MANIFEST.exists():
    sys.exit(f'Manifeste introuvable : {MANIFEST}')

xml = MANIFEST.read_text(encoding='utf-8')

# ---------------------------------------------------------------- 1 et 2
if 'android.permission.INTERNET' not in xml:
    xml = re.sub(
        r'(<manifest[^>]*>)',
        r'\1\n'
        r'    <uses-permission android:name="android.permission.INTERNET"/>\n'
        r'    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>\n'
        r'    <uses-permission android:name="android.permission.WAKE_LOCK"/>',
        xml,
        count=1,
    )
    print('Permissions ajoutees.')

if 'usesCleartextTraffic' not in xml:
    xml = xml.replace(
        '<application',
        '<application\n        android:usesCleartextTraffic="true"',
        1,
    )
    print('Trafic HTTP autorise.')

# -------------------------------------------------------------------- 3
# Android TV : declarer que ni le tactile ni le telephone ne sont requis,
# sinon l application n apparait pas sur le Play Store des televiseurs.
if 'android.software.leanback' not in xml:
    xml = re.sub(
        r'(<manifest[^>]*>)',
        r'\1\n'
        r'    <uses-feature android:name="android.software.leanback" android:required="false"/>\n'
        r'    <uses-feature android:name="android.hardware.touchscreen" android:required="false"/>\n'
        r'    <uses-feature android:name="android.hardware.telephony" android:required="false"/>',
        xml,
        count=1,
    )
    print('Fonctionnalites Android TV declarees.')

# Banniere affichee sur l ecran d accueil des televiseurs.
banniere = pathlib.Path('assets/icon/banner.png')
if banniere.exists():
    dossier = RACINE / 'res' / 'drawable'
    dossier.mkdir(parents=True, exist_ok=True)
    shutil.copy(banniere, dossier / 'banner.png')
    if 'android:banner' not in xml:
        xml = xml.replace(
            '<application',
            '<application\n        android:banner="@drawable/banner"',
            1,
        )
    print('Banniere Android TV installee.')

# Point d entree specifique aux televiseurs.
if 'LEANBACK_LAUNCHER' not in xml:
    xml = xml.replace(
        '<category android:name="android.intent.category.LAUNCHER"/>',
        '<category android:name="android.intent.category.LAUNCHER"/>\n'
        '                <category android:name="android.intent.category.LEANBACK_LAUNCHER"/>',
        1,
    )
    print('Lanceur Android TV ajoute.')

# -------------------------------------------------------------------- 4
# Picture-in-picture : l activite doit le declarer et accepter d etre
# redimensionnee.
if 'supportsPictureInPicture' not in xml:
    xml = xml.replace(
        '<activity',
        '<activity\n            android:supportsPictureInPicture="true"\n'
        '            android:resizeableActivity="true"',
        1,
    )
    print('Picture-in-picture declare.')

MANIFEST.write_text(xml, encoding='utf-8')
print('Manifeste OK.')

# --- Pont Kotlin pour declencher le PiP depuis Dart -----------------------
activites = list(RACINE.glob('kotlin/**/MainActivity.kt'))
if not activites:
    activites = list(RACINE.glob('java/**/MainActivity.kt'))

if not activites:
    print('MainActivity.kt introuvable : PiP non installe (non bloquant).')
else:
    chemin = activites[0]
    paquet = re.search(r'^package\s+([\w.]+)', chemin.read_text(encoding='utf-8'),
                       re.MULTILINE)
    if not paquet:
        print('Paquet Kotlin illisible : PiP non installe (non bloquant).')
    else:
        chemin.write_text(f'''package {paquet.group(1)}

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {{

    private val canal = "iptv/pip"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {{
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canal)
            .setMethodCallHandler {{ appel, reponse ->
                when (appel.method) {{
                    "disponible" -> reponse.success(
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                    )
                    "entrer" -> reponse.success(entrerPip())
                    else -> reponse.notImplemented()
                }}
            }}
    }}

    private fun entrerPip(): Boolean {{
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {{
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
        }} catch (e: Exception) {{
            false
        }}
    }}
}}
''', encoding='utf-8')
        print(f'Pont picture-in-picture installe dans {chemin}')

print('Patch Android termine.')
