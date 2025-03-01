import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioCache _player = AudioCache(prefix: 'assets/sound/');  // 確保路徑正確

  static Future<void> playSound(String fileName, {double volume = 1.0}) async {
    await _player.play(fileName, volume: volume);
  }

  static Future<void> playJumpSound() async {
    await playSound('jump.mp3', volume: 0.5);  // 設置音量為原來的一半
  }
}
