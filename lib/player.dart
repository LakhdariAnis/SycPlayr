import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'favorites.dart';
import 'favorites_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart';
import 'syc_archive.dart';
import 'songs_data.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SycPlayr",
          style: TextStyle(color: Color.fromARGB(255, 2, 9, 83)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArchive02,
              color: Color.fromARGB(255, 2, 9, 83),
              size: 24.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                SlideFromTopRoute(page: const SycArchive()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [const SizedBox(height: 55), const DynamicControls()],
          ),
        ),
      ),
    );
  }
}

class DynamicControls extends StatefulWidget {
  const DynamicControls({super.key});

  @override
  State<DynamicControls> createState() => _DynamicControlsState();
}

class _DynamicControlsState extends State<DynamicControls>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  static const platform = MethodChannel('com.sycplayr.music/command');
  double _turns = 0.0;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;

  void _changeRotation() {
    setState(() {
      _turns += 1.0;
    });
  }

  bool isPlaying = false;
  bool showButtons = false;
  bool isFavorite = false;
  int _currentIndex = 0;

  List<Song> _deviceSongs = [];
  bool _songsLoaded = false;

  Song get currentSong =>
      _deviceSongs.isNotEmpty ? _deviceSongs[_currentIndex] : const Song(
        title: 'No Songs',
        artist: 'Unknown',
        album: '',
        duration: '0:00',
        lyrics: '',
      );

  Future<void> _requestPermissions() async {
    // Android 13+ requires explicit notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    // Request audio permission for reading device MP3s (Android 13+)
    if (await Permission.audio.isDenied) {
      await Permission.audio.request();
    }
  }

  Future<void> _loadDeviceSongs() async {
    try {
      final List<Song> songs = await SongsData.loadDeviceSongs();
      if (mounted) {
        setState(() {
          _deviceSongs = songs;
          _songsLoaded = true;
          _currentIndex = 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading device songs: $e');
    }
  }



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SongsData.requestedSong.addListener(_onRequestedSongChanged);

    // Set up channel listener for state updates
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onStateChanged') {
        final playing = call.arguments['isPlaying'] as bool? ?? false;
        if (mounted && isPlaying != playing) {
          setState(() {
            isPlaying = playing;
            showButtons =
                true; // ensure buttons remain visible if state changes remotely
          });
        }
      } else if (call.method == 'onNext') {
        if (_deviceSongs.isNotEmpty) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _deviceSongs.length;
            showButtons = true;
          });
          _play();
        }
      } else if (call.method == 'onPrevious') {
        if (_deviceSongs.isNotEmpty) {
          setState(() {
            _currentIndex = (_currentIndex - 1 + _deviceSongs.length) % _deviceSongs.length;
            showButtons = true;
          });
          _play();
        }
      }
    });

    _requestPermissions().then((_) => _loadDeviceSongs());

    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_heartAnimationController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      routeObserver.subscribe(this, route);
    }
  }

  void _onRequestedSongChanged() {
    final song = SongsData.requestedSong.value;
    if (song != null && _deviceSongs.isNotEmpty) {
      final idx = _deviceSongs.indexWhere((s) => s.uri == song.uri);
      if (idx != -1) {
        setState(() {
          _currentIndex = idx;
          isPlaying = true;
          showButtons = true;
        });
        _play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _heartAnimationController.dispose();
    SongsData.requestedSong.removeListener(_onRequestedSongChanged);
    platform.invokeMethod('stop'); // Stop playing when completely exiting
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isPlaying) {
      if (state == AppLifecycleState.paused) {
        _stop();
      } else if (state == AppLifecycleState.resumed) {
        _play();
      }
    }
  }

  @override
  void didPushNext() {
    if (isPlaying) {
      _stop(); // pause audio while away
    }
  }

  @override
  void didPopNext() {
    if (isPlaying) {
      _play(); // resume audio
    }
  }

  Future<void> _play() async {
    try {
      await platform.invokeMethod('play', {
        'title': currentSong.title,
        'artist': currentSong.artist,
        'uri': currentSong.uri ?? '',
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to play: '${e.message}'.");
    }
  }

  Future<void> _stop() async {
    try {
      await platform.invokeMethod('pause');
    } on PlatformException catch (e) {
      debugPrint("Failed to stop: '${e.message}'.");
    }
  }

  void _toggleFavorite() {
    final title = currentSong.title;
    FavoritesManager.instance.toggleFavorite(title);
    _heartAnimationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedRotation(
          turns: _turns,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/image.jpg',
              width: 350,
              height: 350,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 75),
        AnimatedOpacity(
          opacity: showButtons ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: SizedBox(
            height: 50,
            width: MediaQuery.of(context).size.width * 0.85,
            child: Marquee(
              text: '${currentSong.artist} - ${currentSong.title}',
              style: GoogleFonts.lato(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 2, 9, 83),
              ),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: 40.0,
              velocity: 30.0,
              startPadding: 10.0,
              pauseAfterRound: const Duration(seconds: 1),
              accelerationDuration: const Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          ),
        ),
        const SizedBox(height: 50),

        AnimatedOpacity(
          opacity: showButtons ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 51.0),
              trackHeight: 2,
            ),
            child: Slider(
              value: 0.5,
              onChanged: (value) {},
              activeColor: const Color.fromARGB(255, 8, 53, 89),
              inactiveColor: const Color.fromARGB(255, 186, 209, 236),
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: showButtons ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IconButton(
                iconSize: 50,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedPrevious,
                  color: Color.fromARGB(255, 2, 9, 83),
                  size: 50.0,
                ),
                onPressed: _deviceSongs.isEmpty ? null : () {
                  setState(() {
                    _currentIndex =
                        (_currentIndex - 1 + _deviceSongs.length) %
                        _deviceSongs.length;
                    isPlaying = true;
                    showButtons = true;
                  });
                  _play();
                },
              ),
            ),
            IconButton(
              iconSize: 60,
              icon: HugeIcon(
                icon: isPlaying
                    ? HugeIcons.strokeRoundedPauseCircle
                    : HugeIcons.strokeRoundedPlayCircle,
                color: Color.fromARGB(255, 2, 9, 83),
                size: 60.0,
              ),
              onPressed: _deviceSongs.isEmpty ? null : () {
                setState(() {
                  showButtons = true;
                  isPlaying = !isPlaying;
                });
                if (isPlaying) {
                  _play();
                } else {
                  _stop();
                }
              },
            ),
            AnimatedOpacity(
              opacity: showButtons ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IconButton(
                iconSize: 50,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedNext,
                  color: const Color.fromARGB(255, 2, 9, 83),
                  size: 50.0,
                ),
                onPressed: _deviceSongs.isEmpty ? null : () {
                  setState(() {
                    _currentIndex =
                        (_currentIndex + 1) % _deviceSongs.length;
                    isPlaying = true;
                    showButtons = true;
                  });
                  _play();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        AnimatedOpacity(
          opacity: showButtons ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: GestureDetector(
            onDoubleTap: _changeRotation,

            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Favorites()),
              );
            },
            child: ScaleTransition(
              scale: _heartScaleAnimation,
              child: ValueListenableBuilder<List<String>>(
                valueListenable: FavoritesManager.instance.favoriteTitles,
                builder: (context, favoriteTitles, child) {
                  final isFav = favoriteTitles.contains(currentSong.title);
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                    color: isFav
                        ? Colors.red
                        : const Color.fromARGB(255, 2, 9, 83),
                    onPressed: _toggleFavorite,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
