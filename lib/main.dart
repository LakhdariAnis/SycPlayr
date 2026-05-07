import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'player.dart'; // Import your new file
import 'favorites_manager.dart';

/// Global RouteObserver so pages can react to navigation events.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritesManager.instance.loadFavorites();
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      navigatorObservers: [routeObserver],
      home: const PlayerPage(), // Call the class from your other file
    );
  }
}
