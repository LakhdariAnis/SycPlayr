import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter/foundation.dart';

class Song {
  final int? id; // SQLite needs an ID to identify which song to delete
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String lyrics;
  final String? uri; // Content URI for device audio files

  const Song({
    this.id, // Optional: auto-incremented by DB
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.lyrics,
    this.uri,
  });

  // Convert a Song into a Map. The keys must match the DB column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'lyrics': lyrics,
      'uri': uri,
    };
  }

  // Extract a Song object from a Map.
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      album: map['album'],
      duration: map['duration'],
      lyrics: map['lyrics'],
      uri: map['uri'],
    );
  }
}

class SongsData {
  static List<Song> allDeviceSongs = [];
  static final ValueNotifier<Song?> requestedSong = ValueNotifier(null);

  static List<Song> _processSongsInBackground(
    List<Map<String, dynamic>> rawSongs,
  ) {
    return rawSongs
        .where((s) => s['fileExtension'] == 'mp3')
        .map(
          (s) => Song(
            title: s['title'] as String,
            artist: s['artist'] as String? ?? 'Unknown Artist',
            album: s['album'] as String? ?? 'Unknown Album',
            duration: _formatDuration(s['duration'] as int? ?? 0),
            lyrics: '',
            uri: s['uri'] as String?,
          ),
        )
        .toList();
  }

  static Future<List<Song>> loadDeviceSongs() async {
    if (allDeviceSongs.isNotEmpty) return allDeviceSongs;
    final OnAudioQuery audioQuery = OnAudioQuery();
    try {
      // 1. Run the platform channel query on the main isolate
      final List<SongModel> songs = await audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      // 2. Convert SongModel objects to plain Maps to pass securely across isolates
      final List<Map<String, dynamic>> rawSongsData = songs
          .map(
            (s) => {
              'title': s.title,
              'artist': s.artist,
              'album': s.album,
              'duration': s.duration,
              'uri': s.uri,
              'fileExtension': s.fileExtension,
            },
          )
          .toList();

      // 3. Spawns a background isolate to do the heavy filtering & mapping
      allDeviceSongs = await compute(_processSongsInBackground, rawSongsData);
    } catch (e) {
      // Ignore query errors
    }
    return allDeviceSongs;
  }

  static String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
