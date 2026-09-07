import 'dart:io';

import 'package:flutter/services.dart';

/// Pont vers le picture-in-picture Android.
///
/// Le code natif est injecte dans MainActivity par tool/patch_android.py :
/// aucun plugin tiers n est necessaire. Sur Windows, tout est inactif.
class PipService {
  static const MethodChannel _canal = MethodChannel('iptv/pip');

  static bool? _disponible;

  /// Vrai si l appareil sait faire du PiP (Android 8 et plus).
  static Future<bool> disponible() async {
    if (!Platform.isAndroid) return false;
    if (_disponible != null) return _disponible!;
    try {
      _disponible = await _canal.invokeMethod<bool>('disponible') ?? false;
    } on PlatformException {
      _disponible = false;
    } on MissingPluginException {
      _disponible = false;
    }
    return _disponible!;
  }

  /// Reduit la lecture en fenetre flottante. Renvoie faux si refuse.
  static Future<bool> entrer() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _canal.invokeMethod<bool>('entrer') ?? false;
    } catch (_) {
      return false;
    }
  }
}
