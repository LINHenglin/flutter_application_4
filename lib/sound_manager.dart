import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _player.setSource(AssetSource('sounds/click.mp3'));
      _isInitialized = true;
      debugPrint('音效系统初始化成功');
    } catch (e) {
      debugPrint('音效系统初始化失败: $e');
    }
  }

  Future<void> playClickSound() async {
    if (!_isInitialized) {
      debugPrint('音效系统未初始化，跳过播放');
      return;
    }

    try {
      await _player.seek(Duration.zero);
      await _player.resume();
      debugPrint('播放点击音效');
    } catch (e) {
      debugPrint('播放音效失败: $e');
    }
  }

  void dispose() {
    _player.dispose();
    _isInitialized = false;
    debugPrint('音效系统已释放');
  }
}
