import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'audio_player_manager.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerManager>(
      builder: (context, player, child) {
        if (player.audioUrl == null) return const SizedBox.shrink();
        return Material(
          elevation: 8,
          color: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          shadowColor: Colors.black.withOpacity(0.2),
          child: InkWell(
            onTap: () {

            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (player.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: player.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 48,
                                height: 48,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AnimatedScrollingText(
                              text: player.title ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              pauseDuration: const Duration(seconds: 1),
                            ),
                            Text(
                              player.description ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          player.audioPlayer.playerState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.blue,
                          size: 32,
                        ),
                        onPressed: () async {
                          if (player.audioPlayer.playerState.playing) {
                            await player.pause();
                          } else {

                            if (player.audioPlayer.playerState.processingState == ProcessingState.idle && player.audioUrl != null) {
                              await player.initialize(
                                audioUrl: player.audioUrl!,
                                title: player.title ?? '',
                                description: player.description ?? '',
                                imageUrl: player.imageUrl ?? '',
                                startPosition: player.position,
                              );
                            }
                            await player.resume();
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${player.position != null ? _formatDuration(player.position!) : '00:00'} / ',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45),
                      ),
                      Text(
                        player.duration != null ? _formatDuration(player.duration!) : '00:00',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
}

class _AnimatedScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration pauseDuration;

  const _AnimatedScrollingText({
    required this.text,
    required this.style,
    this.pauseDuration = const Duration(seconds: 1),
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedScrollingText> createState() => _AnimatedScrollingTextState();
}

class _AnimatedScrollingTextState extends State<_AnimatedScrollingText> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  double _textWidth = 0;
  double _containerWidth = 0;
  bool _isAnimating = false;
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndAnimate());
  }

  @override
  void didUpdateWidget(covariant _AnimatedScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndAnimate());
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _measureAndAnimate() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final RenderBox? textBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? containerBox = context.findRenderObject() as RenderBox?;
    if (textBox != null && containerBox != null) {
      _textWidth = textBox.size.width;
      _containerWidth = containerBox.size.width;
      if (_textWidth > _containerWidth) {
        _startScrollAnimation();
      } else {
        _animationController.stop();
        _scrollController.jumpTo(0);
      }
    }
  }

  void _startScrollAnimation() async {
    if (_isAnimating) return;
    _isAnimating = true;
    final int durationMs = (_textWidth * 7).toInt().clamp(100, 500);
    _animationController.duration = Duration(milliseconds: durationMs);
    while (mounted && _textWidth > _containerWidth) {
      await _animationController.forward(from: 0);
      await Future.delayed(widget.pauseDuration);
      if (!mounted) break;
      _scrollController.jumpTo(0);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _isAnimating = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _containerWidth = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            double offset = 0;
            if (_textWidth > _containerWidth) {
              offset = _animationController.value * (_textWidth - _containerWidth);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(offset);
                }
              });
            }
            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.text,
                key: _textKey,
                style: widget.style,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            );
          },
        );
      },
    );
  }
}
