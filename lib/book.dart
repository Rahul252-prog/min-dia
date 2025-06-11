import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:min_dia/listener_page.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'audio_player_manager.dart';
import 'mini_player.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> with WidgetsBindingObserver {
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
    final books = [
      {
        'audioUrl': 'https://daq7nasbr6dck.cloudfront.net/atomic_habits/1.mp3',
        'title': 'Atomic Habits',
        'description': 'An Easy & Proven Way to Build Good Habits & Break Bad Ones by James Clear.',
        'imageUrl': 'https://images-na.ssl-images-amazon.com/images/I/91bYsX41DVL.jpg',
      },
      {
        'audioUrl': 'https://daq7nasbr6dck.cloudfront.net/sapiens/story_1.wav',
        'title': 'Sapiens',
        'description': 'A Brief History of Humankind by Yuval Noah Harari.',
        'imageUrl': 'https://images-na.ssl-images-amazon.com/images/I/713jIoMO3UL.jpg',
      },
      {
        'audioUrl': 'http://daq7nasbr6dck.cloudfront.net/7habits/1.mp3',
        'title': '7 Habits of Highly Effective People',
        'description': 'Powerful Lessons in Personal Change by Stephen R. Covey.',
        'imageUrl': 'http://daq7nasbr6dck.cloudfront.net/7habits/cover.jpg',
      },
    ];
    final player = Provider.of<AudioPlayerManager>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Books')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            final isCurrent = player.audioUrl == book['audioUrl'];
            return GestureDetector(
              onTap: () async {
                if (isCurrent) {
                  // Resume from current position
                  player.initialize(
                    audioUrl: book['audioUrl']!,
                    title: book['title']!,
                    description: book['description']!,
                    imageUrl: book['imageUrl']!,
                    startPosition: player.position,
                  );
                  player.resume();
                } else {
                  // Start from beginning
                  player.play(
                    audioUrl: book['audioUrl']!,
                    title: book['title']!,
                    description: book['description']!,
                    imageUrl: book['imageUrl']!,
                    startPosition: Duration.zero,
                  );
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PodcastListenerWidget(),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: book['imageUrl']!,
                          width: 100,
                          height: 140,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 100,
                              height: 140,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        book['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book['description']!,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
