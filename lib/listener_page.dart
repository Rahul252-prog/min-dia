import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'audio_player_manager.dart';

class PodcastListenerWidget extends StatefulWidget {
  const PodcastListenerWidget({super.key});

  @override
  State<PodcastListenerWidget> createState() => _PodcastListenerWidgetState();
}

class _PodcastListenerWidgetState extends State<PodcastListenerWidget> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final player = Provider.of<AudioPlayerManager>(context, listen: false);
      player.calculateListeningPercentage();
      player.saveState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<AudioPlayerManager>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (player.imageUrl != null)
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1200),
                    child: CachedNetworkImage(
                      imageUrl: player.imageUrl!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 200,
                          height: 200,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 200),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                player.title ?? '',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                player.description ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              // Position and duration display above the slider
              Column(
                spacing: 10,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        // Show 00:00 if position is null or duration is null or zero
                        '${(player.position == null || player.duration == null || player.duration == Duration.zero) ? '00:00' : _formatDuration(player.position!)} / ',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      Text(
                        (player.duration == null || player.duration == Duration.zero)
                            ? '00:00'
                            : _formatDuration(player.duration!),
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // Remove thumb
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: (player.position == null || player.duration == null || player.duration == Duration.zero)
                          ? 0
                          : player.position!.inSeconds.toDouble(),
                      min: 0,
                      max: (player.duration == null || player.duration == Duration.zero)
                          ? 1
                          : player.duration!.inSeconds.toDouble(),
                      onChanged: (value) {
                        player.seek(Duration(seconds: value.toInt()));
                      },
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: Colors.grey[300],
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_30),
                    onPressed: () {
                      final newPos = (player.position ?? Duration.zero) - const Duration(seconds: 30);
                      player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                    },
                  ),
                  IconButton(
                    icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 64,
                    onPressed: () {
                      if (player.isPlaying) {
                        player.pause();
                      } else {
                        player.resume();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_30),
                    onPressed: () {
                      final dur = player.duration ?? Duration.zero;
                      final newPos = (player.position ?? Duration.zero) + const Duration(seconds: 30);
                      player.seek(newPos > dur ? dur : newPos);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to format duration
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final hours = d.inHours;
    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
