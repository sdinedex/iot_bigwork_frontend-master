import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:iot/mqtt.dart';
import 'package:iot/recordButton.dart';
import 'package:iot/speechRecognize.dart';
import 'package:iot/translation.dart';
import 'package:iot/values.dart';
import 'package:mqtt_client/mqtt_client.dart';

class Chat extends StatefulWidget {
  final String title;
  const Chat({super.key, required this.title});
   


   
  @override 
  State<Chat> createState() => _ChatState();
}

Widget _buildItem(BuildContext context, int i) {
  return Column(
    crossAxisAlignment:
        Values.messageItems[i]["srcUserEmail"] == Values.userEmail
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Text(Values.messageItems[i]["srcUserEmail"] == Values.userEmail
            ? Values.userName
            : Values.dstUserName),
      ),
      Container(
          margin: EdgeInsets.only(
              left: Values.messageItems[i]["srcUserEmail"] == Values.userEmail
                  ? 50
                  : 10,
              right: Values.messageItems[i]["srcUserEmail"] == Values.userEmail
                  ? 10
                  : 50,
              bottom: 10),
          child: ListTile(
              tileColor:
                  Values.userEmail == Values.messageItems[i]["srcUserEmail"]!
                      ? const Color.fromARGB(70, 76, 175, 79)
                      : const Color.fromARGB(70, 33, 149, 243),
              textColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Values.messageItems[i]["type"]! == "text"
                  ? SelectableText(Values.messageItems[i]["content"]!)
                  : Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              var player = AudioPlayer();
                              String uri =
                                  "${Values.fileUri}/${Values.messageItems[i]["content"]}";
                              player.play(uri);
                            },
                            icon: const Icon(Icons.play_circle)),
                        const Text("语音消息  "),
                        TextButton(
                            onPressed: () {
                              String uri =
                                  "${Values.fileUri}/${Values.messageItems[i]["content"]}";
                              SpeechRecognize.recognize(uri, "chinese")
                                  .then((value) => showDialog(
                                      context: context,
                                      builder: ((context) => AlertDialog(
                                            title: const Text("转文字"),
                                            content: SelectableText(value),
                                            actions: [
                                              TextButton(
                                                  onPressed: (() {
                                                    Navigator.of(context).pop();
                                                  }),
                                                  child: const Text("确定"))
                                            ],
                                          ))));
                            },
                            child: const Text("转文字")),
                        TextButton(
                            onPressed: () {
                              String uri =
                                  "${Values.fileUri}/${Values.messageItems[i]["content"]}";
                              SpeechRecognize.recognize(uri, "english").then(
                                  (value) => Translation.translate(value)
                                      .then((value) => showDialog(
                                          context: context,
                                          builder: ((context) => AlertDialog(
                                                title: const Text("英译中"),
                                                content: SelectableText(value),
                                                actions: [
                                                  TextButton(
                                                      onPressed: (() {
                                                        Navigator.of(context)
                                                            .pop();
                                                      }),
                                                      child: const Text("确定"))
                                                ],
                                              )))));
                            },
                            child: const Text("翻译"))
                      ],
                    )))
    ],
  );
}

class _ChatState extends State<Chat> {
  String _inputText = "";
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textEditingController = TextEditingController();
  late Timer _timer;

  _onListen(List<MqttReceivedMessage<MqttMessage?>>? c) {
    final recMess = c![0].payload as MqttPublishMessage;
    final pt = utf8.decode(recMess.payload.message).split("|");
    String flag = "${pt[0]}chat";
    if (Values.received.contains(flag)) return;
    Values.received.add(flag);
    if (pt[1] == Values.userEmail || pt[1] != Values.dstUserEmail) {
      return;
    } else if (pt[2] == '@') {
      return;
    } else if (pt[2] == "#") {
      return;
    } else if (pt[2] == "\$") {
      Values.messageItems.add({
        "time": pt[0],
        "srcUserEmail": Values.dstUserEmail,
        "dstUserEmail": Values.userEmail,
        "type": "audio",
        "content": pt[3]
      });
    } else {
      String mes = "";
      for (int i = 2; i < pt.length; i++) {
        mes += pt[i];
      }
      Values.messageItems.add({
        "time": pt[0],
        "srcUserEmail": Values.dstUserEmail,
        "dstUserEmail": Values.userEmail,
        "type": "text",
        "content": mes
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  void initState() {
    super.initState();
    if (Values.isChatMqttStarted == false) {
      while (true) {
        if (Mqtt.client.subscribe(Values.userEmail, MqttQos.exactlyOnce) !=
            null) {
          break;
        } else {
          Mqtt.client.connect();
        }
      }
      Mqtt.client.updates!.listen(_onListen);
      Values.isChatMqttStarted = true;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (Values.autoScroll == false) {
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
                onPressed: (() {
                  Values.autoScroll = !Values.autoScroll;
                  setState(() {});
                }),
                icon: Icon(
                    Values.autoScroll == true ? Icons.lock : Icons.lock_open)),
          ],
          title: Text(widget.title),
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                controller: _scrollController,
                itemCount: Values.messageItems.length,
                itemBuilder: _buildItem),
          ),
          // ),
          Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    alignment: AlignmentDirectional.center,
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: const Icon(
                        Icons.mic,
                        size: 30,
                      ),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: ((context) => const AlertDialog(
                                title: Text("按住图标开始录音"),
                                content: RecordButton())));
                      },
                    ),
                  ),
                  Flexible(
                      child: TextFormField(
                    controller: _textEditingController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: "在此输入您想要发送的消息"),
                    onChanged: ((value) => _inputText = value),
                  )),
                  Container(
                      alignment: AlignmentDirectional.center,
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      child: IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: const Icon(
                          Icons.send,
                          size: 30,
                        ),
                        onPressed: () {
                          Mqtt.toPublish(_inputText);
                          Values.messageItems.add({
                            "srcUserEmail": Values.userEmail,
                            "dstUserEmail": Values.dstUserEmail,
                            "type": "text",
                            "content": _inputText
                          });
                          _textEditingController.text = "";
                          _inputText = "";
                          int count = 2;
                          Timer.periodic(const Duration(milliseconds: 50),
                              (timer) {
                            if (count < 0) {
                              timer.cancel();
                            }
                            count--;
                            setState(() {});
                            _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent);
                          });
                        },
                      ))
                ],
              )),
        ]));
  }
}
