import 'dart:core';
import 'dart:math';

import 'package:iot/values.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

const String = "a";

class Mqtt {
  static MqttServerClient client = MqttServerClient(Values.brokerIp, "1883");

  static Future<void> onDisconnected() async {
    print('OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('OnDisconnected callback is solicited, this is correct');
    }
    await client.connect();
  }

  static void onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
  }

  static void onConnected() {
    print('OnConnected client callback - Client connection was sucessful');
  }

  static Future<void> toPublish(String text) async {
    final builder = MqttClientPayloadBuilder();
    text = "${DateTime.now().millisecondsSinceEpoch}|${Values.userEmail}|$text";
    builder.addUTF8String(text);
    print('Publishing our topic');
    if (client.connectionStatus!.state != MqttConnectionState.connected) {
      await client.connect();
    }
    client.publishMessage(
        Values.dstUserEmail, MqttQos.exactlyOnce, builder.payload!);
  }

  static Future<void> mqttStart() async {
    client.logging(on: false);
    client.keepAlivePeriod = 3600;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
    final connMess = MqttConnectMessage()
        .withClientIdentifier(getRandomString(10))
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.exactlyOnce);
    print('Client connecting....');
    client.connectionMessage = connMess;
    try {
      await client.connect();
    } catch (e) {
      print('Socket exception: $e');
      client.disconnect();
    }
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Client connected');
    }

    Mqtt.client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      print("test received");
    });
  }

  static String getRandomString(int length) {
    const characters =
        '+-*=?AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }
}
