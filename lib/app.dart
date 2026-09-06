import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class IptvApp extends StatelessWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00B4D8),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Lecteur IPTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF10141A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF161B22),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF7FD4E8),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
