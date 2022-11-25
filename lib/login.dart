import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iot/contact.dart';
import 'package:iot/mqtt.dart';
import 'package:iot/register.dart';
import 'package:http/http.dart' as http;
import 'package:iot/values.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'iot',
      home: LoginWidget(),
    );
  }
}

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  var _userEmail = "";
  var _userPassword = "";
  var _userName = "";

  void showMyDialog(String text) {
    showDialog(
        context: context,
        builder: ((context) => AlertDialog(
              title: const Text("提示"),
              content: Text(text),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("确定"))
              ],
            )));
  }

  Future<dynamic> userQuery() async {
    Values.contactItems = <Map<String, String>>[];
    final response = await http.get(Uri.parse("${Values.baseUri}/user_query"));
    String utf8Body = utf8.decode(response.bodyBytes);
    Map<String, dynamic> responseBody = json.decode(utf8Body);
    List<dynamic> content = responseBody["content"];
    for (int i = 0; i < content.length; i++) {
      Map<String, dynamic> mp = content[i];
      Map<String, String> myMap = {};
      for (String key in mp.keys) {
        myMap[key] = mp[key].toString();
      }
      Values.contactItems.add(myMap);
    }
  }

  Future<int> userLogin() async {
    var requestBody = {
      "user_email": _userEmail,
      "user_password": _userPassword
    };
    int result = 0;
    try {
      final response = await http
          .post(Uri.parse("${Values.baseUri}/user_login"), body: requestBody);
      if (response.statusCode == 200) {
        var utf8ResponseBody = utf8.decode(response.bodyBytes);
        Map<String, dynamic> responseBody = json.decode(utf8ResponseBody);
        result = responseBody["code"];
        if (result == 0) _userName = responseBody["user_name"];
      } else {
        result = 100;
      }
    } catch (e) {
      result = 101;
    }
    return result;
  }

  void _onPressedLogin() async {
    if (_userEmail == '') {
      showMyDialog("邮箱不能为空");
      return;
    } else if (_userPassword == '') {
      showMyDialog("密码不能为空");
      return;
    }
    int code = 0;
    await userLogin().then((value) => code = value);
    if (code == 0) {
      Values.userEmail = _userEmail;
      Values.userName = _userName;
      showMyDialog("登录成功");
      await userQuery().then((value) => null);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: ((context) => Contact(
                    title: '$_userName 的联系人',
                  )))).then((value) {
        Mqtt.client.unsubscribe(Values.userEmail);
      });
    } else if (code == 2) {
      showMyDialog("密码不正确，请重新输入");
    } else if (code == 3) {
      showMyDialog("用户不存在，请先注册");
    } else if (code == 100) {
      showMyDialog("未知错误，请联系管理员");
    } else if (code == 101) {
      showMyDialog("网络不可达");
    }
  }

  void _onPressedRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Register()),
    );
  }

  @override
  Widget build(BuildContext context) {
    Mqtt.mqttStart();
    return Scaffold(
      appBar: AppBar(
        title: const Text("登录"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin:
                const EdgeInsets.only(left: 10, top: 20, right: 10, bottom: 10),
            child: TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '邮箱',
              ),
              onChanged: ((value) => _userEmail = value),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '密码',
              ),
              onChanged: ((value) => _userPassword = value),
            ),
          ),
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              child: ElevatedButton(
                  onPressed: _onPressedLogin,
                  child: const Text(
                    "登录",
                  ))),
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.all(10),
            child: TextButton(
              onPressed: _onPressedRegister,
              child: const Text("没有账号？点击注册"),
            ),
          )
        ],
      ),
    );
  }
}
