import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'favorites_manager.dart';
import 'songs_data.dart';

Future<void> _confirmRemoveFavorite(BuildContext context, Song song) async {
  final shouldRemove = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remove from favorites?'),
      content: Text('Are you sure you want to remove "${song.title}" from your favorites?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Remove'),
        ),
      ],
    ),
  );

  if (shouldRemove == true) {
    FavoritesManager.instance.removeFavorite(song.title);
  }
}

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    await SongsData.loadDeviceSongs();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Favorites",
          style: TextStyle(color: Color.fromARGB(255, 2, 9, 83)),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<List<String>>(
              valueListenable: FavoritesManager.instance.favoriteTitles,
        builder: (context, favoriteTitles, child) {
          if (favoriteTitles.isEmpty) {
            return Center(
              child: Text(
                "Your favorite songs will appear here!",
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 2, 9, 83),
                ),
              ),
            );
          }

          final favoriteSongs = favoriteTitles
              .map((title) {
                return SongsData.allDeviceSongs
                    .where((song) => song.title == title)
                    .firstOrNull;
              })
              .whereType<Song>()
              .toList();

          return ListView.builder(
            itemCount: favoriteSongs.length,
            itemBuilder: (context, index) {
              final song = favoriteSongs[index];
              return ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: Text(
                  song.title,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 2, 9, 83),
                  ),
                ),
                subtitle: Text(song.artist),
                onLongPress: () => _confirmRemoveFavorite(context, song),
              );
            },
          );
        },
      ),
    );
  }
}
