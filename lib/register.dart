import 'dart:convert';

import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'package:iot/values.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  var _userEmail = "";
  var _userName = "";
  var _userPassword = "";
  var _userPasswordReconfirm = "";

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

  Future<int> userRigister() async {
    var requestBody = {
      "user_email": _userEmail,
      "user_name": _userName,
      "user_password": _userPassword
    };
    int result = 0;
    try {
      final response = await http.post(
          Uri.parse("${Values.baseUri}/user_register"),
          body: requestBody);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        result = responseBody["code"];
      } else {
        result = 100;
      }
    } catch (e) {
      result = 101;
    }
    return result;
  }

  void _onPressedRegister() async {
    if (_userPassword != _userPasswordReconfirm) {
      showMyDialog("密码不一致，请检查密码");
      return;
    } else if (_userEmail == '') {
      showMyDialog("邮箱不能为空");
      return;
    } else if (_userName == '') {
      showMyDialog("用户名不能为空");
      return;
    } else if (_userPassword == '') {
      showMyDialog("密码不能为空");
      return;
    }
    int code = 0;
    await userRigister().then((value) => code = value);
    if (code == 0) {
      showMyDialog("注册成功，请登录");
      Values.userEmail = _userEmail;
      Values.userPassword = _userPassword;
      if (!mounted) return;
      Navigator.of(context).pop();
    } else if (code == 1) {
      showMyDialog("用户已存在，请重新注册");
    } else if (code == 100) {
      showMyDialog("未知错误，请联系管理员");
    } else if (code == 101) {
      showMyDialog("网络不可达");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("注册"),
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
                labelText: "邮箱(这是唯一标识)",
              ),
              onChanged: ((value) => _userEmail = value),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "用户名",
              ),
              onChanged: ((value) => _userName = value),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "密码",
              ),
              onChanged: ((value) => _userPassword = value),
            ),
          ),
          Container(
              margin: const EdgeInsets.all(10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "确认密码",
                      ),
                      onChanged: ((value) {
                        setState(() {
                          _userPasswordReconfirm = value;
                        });
                      }),
                    ),
                    Text(
                      _userPassword != _userPasswordReconfirm ? "密码不一致" : "",
                      style: const TextStyle(color: Colors.red),
                    )
                  ])),
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: _onPressedRegister,
                child: const Text(
                  "注册",
                ),
              ))
        ],
      ),
    );
  }
}
