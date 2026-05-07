import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'songs_data.dart';
import 'song_detail_view.dart';

class SycArchive extends StatefulWidget {
  const SycArchive({super.key});

  @override
  State<SycArchive> createState() => _SycArchiveState();
}

class _SycArchiveState extends State<SycArchive> {
  List<Song> _songs = [];
  Song? _selectedSong;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await SongsData.loadDeviceSongs();
    if (mounted) {
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Library",
          style: TextStyle(color: Color.fromARGB(255, 2, 9, 83)),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = constraints.maxWidth > 600;

                if (isLandscape) {
            // ── Landscape: list + detail side by side ──
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildSongList(
                    _songs,
                    onTap: (song) {
                      setState(() => _selectedSong = song);
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: _selectedSong != null
                      ? SongDetailView(song: _selectedSong!)
                      : Center(
                          child: Text(
                            "Double tap a song to view details",
                            style: GoogleFonts.lato(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 100, 110, 160),
                            ),
                          ),
                        ),
                ),
              ],
            );
          }

          // ── Portrait: list only, tap pushes detail page ──
          return _buildSongList(
            _songs,
            onTap: (song) {
              SongsData.requestedSong.value = song;
              Navigator.pop(context);
            },
            onDoubleTap: (song) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SongDetailPage(song: song)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSongList(
    List<Song> songs, {
    required ValueChanged<Song> onTap,
    ValueChanged<Song>? onDoubleTap,
  }) {
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isSelected = _selectedSong == song;

        return GestureDetector(
          onDoubleTap: onDoubleTap != null ? () => onDoubleTap(song) : null,
          child: ListTile(
            selected: isSelected,
            selectedTileColor: const Color.fromARGB(
              255,
              2,
              9,
              83,
            ).withValues(alpha: 0.08),
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedMusicNote03,
              color: const Color.fromARGB(255, 2, 9, 83),
              size: 28.0,
            ),
            title: Text(
              song.title,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 2, 9, 83),
              ),
            ),
            subtitle: Text(
              "${song.artist} · ${song.album}",
              style: GoogleFonts.lato(
                fontSize: 14,
                color: const Color.fromARGB(255, 100, 110, 160),
              ),
            ),
            trailing: Text(
              song.duration,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: const Color.fromARGB(255, 100, 110, 160),
              ),
            ),
            onTap: () => onTap(song),
            onLongPress: () => _confirmDeleteSong(song),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSong(Song song) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete song?'),
          content: Text(
            'Are you sure you want to delete "${song.title}" from your library?',
          ),
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _songs.remove(song);
        if (_selectedSong == song) {
          _selectedSong = null;
        }
      });
    }
  }
}

/// Custom route that slides the page in from the top.
class SlideFromTopRoute extends PageRouteBuilder {
  final Widget page;

  SlideFromTopRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, -1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}
