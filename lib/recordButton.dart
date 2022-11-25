import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:iot/mqtt.dart';
import 'package:iot/values.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({super.key});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  static String pathToAudio = '';
  static String audioName = "";
  static String resName = "";
  static bool isRecording = false;
  static const theSource = AudioSource.microphone;
  final Codec _codec = Codec.aacADTS;
  final FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();

  @override
  void initState() {
    super.initState();
    openTheRecorder().then((value) {
    });
  }

  @override
  void dispose() {
    _mRecorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (Container(
      margin: const EdgeInsets.all(10),
      child: GestureDetector(
          onLongPressDown: (details) {
            isRecording = true;
            setState(() {});
            record();
          },
          onLongPressUp: () {
            isRecording = false;
            Navigator.of(context).pop();
            stopRecorder();
            uploadAndSend();
            setState(() {});
          },
          onLongPressCancel: () {
            isRecording = false;
            Navigator.of(context).pop();
            stopRecorder();
            uploadAndSend();
            setState(() {});
          },
          child: IconButton(
            iconSize: 120,
            icon: Icon(
              isRecording == true ? Icons.mic : Icons.mic_none,
              size: 120,
            ),
            onPressed: () {},
          )),
    ));
  }

  uploadAndSend() async {
    await upload();
    Mqtt.toPublish("\$|$resName");
    Values.messageItems.add({
      "srcUserEmail": Values.userEmail,
      "dstUserEmail": Values.dstUserEmail,
      "type": "audio",
      "content": resName
    });
  }

  Future<void> upload() async {
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(pathToAudio, filename: audioName),
      });
      Response response =
          await Dio().post("${Values.baseUri}/upload", data: formData);
      resName = response.data["file_name"];
    } catch (e) {
      return;
    }
  }

  Future<void> openTheRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder.openRecorder();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

  }

  void record() {
    audioName = "${DateTime.now().millisecondsSinceEpoch}.aac";
    pathToAudio = '/storage/emulated/0/Download/$audioName';
    _mRecorder
        .startRecorder(
      toFile: pathToAudio,
      codec: _codec,
      audioSource: theSource,
    )
        .then((value) {
      setState(() {});
    });
  }

  void stopRecorder() async {
    await _mRecorder.stopRecorder().then((value) {});
  }
}
