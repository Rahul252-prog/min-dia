import 'package:flutter/material.dart';
import 'package:min_dia/listener_page.dart';
import 'package:provider/provider.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Book')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                final player = Provider.of<AudioPlayerManager>(context, listen: false);
                player.calculateListeningPercentage();
                player.play(
                  audioUrl: 'http://daq7nasbr6dck.cloudfront.net/7habits/1.mp3',
                  title: '7 Habits of Highly Effective People',
                  description: 'Chapter 1',
                  imageUrl: 'http://daq7nasbr6dck.cloudfront.net/7habits/cover.jpg',
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PodcastListenerWidget(),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.audiotrack, size: 150, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                    'Listen to Book',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
