import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'services/epg_service.dart';
import 'services/prefs_service.dart';
import 'services/stream_check_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise le moteur video (libmpv) pour Android et Windows.
  MediaKit.ensureInitialized();
  await Prefs.init();
  await StreamCheckService.instance.charger();
  await EpgService.instance.chargerDepuisDisque();
  runApp(const IptvApp());
}
