import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio_player_manager.dart';
import 'book.dart';
import 'mini_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final player = Provider.of<AudioPlayerManager>(
        context,
        listen: false,
      );
      player.calculateListeningPercentage();
      player.saveState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Podcast Reader')),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookPage()),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book, size: 150, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Open Book',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
