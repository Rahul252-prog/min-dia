import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerManager extends ChangeNotifier {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  AudioPlayerManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioUrl;
  String? _title;
  String? _description;
  String? _imageUrl;
  Duration? _duration;
  Duration? _position;
  bool _isPlaying = false;
  double? _listeningPercentage;

  // Getters
  String? get audioUrl => _audioUrl;
  String? get title => _title;
  String? get description => _description;
  String? get imageUrl => _imageUrl;
  Duration? get duration => _duration;
  Duration? get position => _position;
  bool get isPlaying => _isPlaying;
  AudioPlayer get audioPlayer => _audioPlayer;
  double? get listeningPercentage => _listeningPercentage;

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _audioUrl = prefs.getString('audioUrl');
    _title = prefs.getString('title');
    _description = prefs.getString('description');
    _imageUrl = prefs.getString('imageUrl');
    final durationMillis = prefs.getInt('duration');
    final positionMillis = prefs.getInt('position');
    _duration = durationMillis != null ? Duration(milliseconds: durationMillis) : null;
    _position = positionMillis != null ? Duration(milliseconds: positionMillis) : null;
    _isPlaying = false;
    notifyListeners();
  }

  // Save state
  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_audioUrl != null) prefs.setString('audioUrl', _audioUrl!);
    if (_title != null) prefs.setString('title', _title!);
    if (_description != null) prefs.setString('description', _description!);
    if (_imageUrl != null) prefs.setString('imageUrl', _imageUrl!);
    if (_duration != null) prefs.setInt('duration', _duration!.inMilliseconds);
    if (_position != null) prefs.setInt('position', _position!.inMilliseconds);
  }

  // Initialize audio source without playing
  Future<void> initialize({
    required String audioUrl,
    required String title,
    required String description,
    required String imageUrl,
    Duration? startPosition,
  }) async {
    _audioUrl = audioUrl;
    _title = title;
    _description = description;
    _imageUrl = imageUrl;
    await _audioPlayer.setUrl(audioUrl);
    if (startPosition != null) {
      await _audioPlayer.seek(startPosition);
    }
    _duration = _audioPlayer.duration;
    _position = _audioPlayer.position;
    saveState();
    notifyListeners();
    _attachListeners();
  }

  // Start playback (play and resume should only start playback)
  Future<void> play({
    required String audioUrl,
    required String title,
    required String description,
    required String imageUrl,
    Duration? startPosition,
  }) async {
    await initialize(
      audioUrl: audioUrl,
      title: title,
      description: description,
      imageUrl: imageUrl,
      startPosition: startPosition,
    );
    await _audioPlayer.play();
    _isPlaying = true;
    saveState();
    notifyListeners();
  }

  void _attachListeners() {
    // Prevent multiple subscriptions
    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      saveState();
      notifyListeners();
    });
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    saveState();
    notifyListeners();
  }

  Future<void> resume() async {
    if (_audioUrl != null && _audioPlayer.playerState.processingState == ProcessingState.idle) {
      await _audioPlayer.setUrl(_audioUrl!);
      if (_position != null) {
        await _audioPlayer.seek(_position!);
      }
    }
    await _audioPlayer.play();
    _isPlaying = true;
    saveState();
    notifyListeners();
    _attachListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    _position = position;
    saveState();
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    saveState();
    notifyListeners();
  }

  void clear() async {
    _audioUrl = null;
    _title = null;
    _description = null;
    _imageUrl = null;
    _duration = null;
    _position = null;
    _isPlaying = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // Calculate listening percentage
  void calculateListeningPercentage() {
    if (_duration != null && _duration!.inMilliseconds > 0 && _position != null) {
      _listeningPercentage = (_position!.inMilliseconds / _duration!.inMilliseconds) * 100;
      print("_listeningPercentage: $_listeningPercentage %");
    } else {
      _listeningPercentage = null;
    }
  }
}
