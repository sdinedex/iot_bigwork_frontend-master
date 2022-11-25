import 'package:flutter_sound/flutter_sound.dart';

class PlayAudio{
  static final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  static bool _mPlayerIsInited = false;

  static void play(String audioUri) async {
    if(_mPlayerIsInited == false){
      _mPlayer.openPlayer();
      _mPlayerIsInited = true;
    }
    assert(_mPlayer.isStopped);
    _mPlayer.startPlayer  (
      fromURI: audioUri,
      codec: Codec.aacMP4
    );
  }

  static void stopPlayer() {
    _mPlayer.stopPlayer();
  }
}