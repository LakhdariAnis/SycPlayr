import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'songs_data.dart';

class SongDetailView extends StatelessWidget {
  final Song song;

  const SongDetailView({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album art placeholder
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 220, 228, 245),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      2,
                      9,
                      83,
                    ).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMusicNote03,
                  color: const Color.fromARGB(255, 2, 9, 83),
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Title
            Text(
              song.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 2, 9, 83),
              ),
            ),
            const SizedBox(height: 8),

            // Artist
            Text(
              song.artist,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: const Color.fromARGB(255, 60, 70, 130),
              ),
            ),
            const SizedBox(height: 6),

            // Album
            Text(
              song.album,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color.fromARGB(255, 100, 110, 160),
              ),
            ),
            const SizedBox(height: 16),

            // Duration chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  2,
                  9,
                  83,
                ).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                song.duration,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 2, 9, 83),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Lyrics
            Text(
              song.lyrics,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.8,
                color: const Color.fromARGB(255, 60, 70, 130),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-page wrapper for portrait navigation
class SongDetailPage extends StatelessWidget {
  final Song song;

  const SongDetailPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          song.title,
          style: const TextStyle(color: Color.fromARGB(255, 2, 9, 83)),
        ),
        centerTitle: true,
      ),
      body: SongDetailView(song: song),
    );
  }
}
