import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playClickSound() async {
    try {
      debugPrint('正在播放音效...');
      // 设置音量
      await _audioPlayer.setVolume(1.0);
      // 先停止当前播放
      await _audioPlayer.stop();
      // 重新加载并播放音效
      await _audioPlayer.play(AssetSource('sounds/点击.mp3'));
      debugPrint('音效播放完成');
    } catch (e) {
      debugPrint('音效播放失败: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
