import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(
    MaterialApp(
      title: 'Galaxy Protocol 2026',
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.orbitronTextTheme(),
      ),
      home: const MainMenu(),
    ),
  );
}
// GameWidget is now launched from the Main Menu.
