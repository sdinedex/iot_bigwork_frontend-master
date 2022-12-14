import 'dart:async';
import 'dart:convert';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iot/values.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'chat.dart';
import 'mqtt.dart';

class Contact extends StatefulWidget {
  final String title;
  const Contact({super.key, required this.title});

  @override
  State<Contact> createState() => _ContactState();
}

class _ContactState extends State<Contact> {
  final List<Map<String, String>> _items = Values.contactItems;
  late Timer _timer;

  _onListen(List<MqttReceivedMessage<MqttMessage?>>? c) {
    final recMess = c![0].payload as MqttPublishMessage;
    final pt = utf8.decode(recMess.payload.message).split("|");
    String flag = "${pt[0]}contact";
    if (Values.received.contains(flag)) return;
    Values.received.add(flag);
    if (pt[1] == Values.userEmail) return;
    if (pt[2] == '@' && Values.isBinded == false) {
      String tmp = "";
      for (int i = 0; i < Values.contactItems.length; i++) {
        if (pt[1] == Values.contactItems[i]["user_email"]) {
          tmp = Values.contactItems[i]["user_name"]!;
          break;
        }
      }
      Values.dstUserEmail = pt[1];
      Values.dstUserName = tmp;
      Values.isAsk = true;
      Values.whoAsk = {"user_name": tmp, "user_email": pt[1]};
      //----------------------------------//

    } else if (pt[2] == '#') {
      Values.isBinded = true;
      Values.messageItems = [];
      Values.isConfirm = true;
      Values.whoAsk = {
        "user_name": Values.dstUserName,
        "user_email": Values.dstUserEmail
      };
      //---------------------------//

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
    Values.isBinded = false;
    Values.isAsk = false;
    Values.isConfirm = false;
    Values.whoAsk = {};

    while (true) {
      if (Mqtt.client.subscribe(Values.userEmail, MqttQos.exactlyOnce) !=
          null) {
        break;
      } else {
        Mqtt.client.connect();
      }
    }
    Mqtt.client.updates!.listen(_onListen);

    _timer = Timer.periodic(const Duration(milliseconds: 100), ((timer) {
      if (Values.isAsk == true) {
        showDialog(
            context: context,
            builder: ((context) => AlertDialog(
                  title: const Text("提示"),
                  content: Text(
                      "用户名${Values.whoAsk["user_name"]}(邮箱${Values.whoAsk["user_email"]})想与你绑定，是否确定?"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("取消")),
                    TextButton(
                        onPressed: (() {
                          Mqtt.toPublish("#");
                          Values.isBinded = true;
                          Values.messageItems = [];
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Chat(title: Values.dstUserName),
                              )).then((value) {
                            Navigator.of(context).pop();
                            Mqtt.toPublish("系统消息：对方已退出");
                            Values.autoScroll = true;
                            Values.isBinded = false;
                          });
                        }),
                        child: const Text("确定"))
                  ],
                )));
        Values.isAsk = false;
      } else if (Values.isConfirm == true) {
        Navigator.push(
                context,
                MaterialPageRoute(
                    builder: ((context) => Chat(title: Values.dstUserName))))
            .then(((value) {
          Mqtt.toPublish("系统消息：对方已退出");
          Values.isBinded = false;
          Values.autoScroll = true;
        }));
        Values.isConfirm = false;
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title),
        ),
        body: ListView.builder(
            itemCount: _items.length * 2, itemBuilder: _buildItem));
  }

  Widget _buildItem(BuildContext context, int i) {
    var index = 0;
    void onItemTap() {
      showDialog(
          context: context,
          builder: ((context) => AlertDialog(
                title: const Text("提示"),
                content: const Text("正在发起绑定请求，等待对方确认"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("确定"))
                ],
              )));
      Values.dstUserEmail = Values.contactItems[index]["user_email"]!;
      Values.dstUserName = Values.contactItems[index]["user_name"]!;
      Mqtt.toPublish("@");
      Values.messageItems = [];
    }

    if (i.isOdd) return const Divider();
    index = i ~/ 2;
    String text = "";
    String text2 = "";
    text = Values.contactItems[index]["user_name"].toString();
    text2 = Values.contactItems[index]["user_email"].toString();
    return ListTile(
      title: Text(text),
      onTap: onItemTap,
      subtitle: Text(text2),
    );
  }
}
