// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class Translation {
  static Future<String> translate(String text) async {
    var dateTime = DateTime.now().toUtc();
    var date = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    var Timestamp = dateTime.millisecondsSinceEpoch.toString().substring(0, 10);
    var Algorithm = "TC3-HMAC-SHA256";
    var CredentialScope = "$date/tmt/tc3_request";
    String SecretKey = " ";
    String SecretId = " ";

    String HTTPRequestMethod = "POST";
    String CanonicalURI = "/";
    String CanonicalQueryString = "";
    String contentType = "application/json; charset=utf-8";
    String CanonicalHeaders =
        "content-type:$contentType\nhost:tmt.tencentcloudapi.com\n";
    String SignedHeaders = "content-type;host";
    var requestBody = {
      "SourceText": text,
      "ProjectId": 0,
      "Target": "zh",
      "Source": "en"
    };
    var jsonRequestBody = jsonEncode(requestBody);
    String HashedRequestPayload =
        sha256.convert(utf8.encode(jsonRequestBody)).toString().toLowerCase();
    String CanonicalRequest =
        "$HTTPRequestMethod\n$CanonicalURI\n$CanonicalQueryString\n$CanonicalHeaders\n$SignedHeaders\n$HashedRequestPayload";
    String HashedCanonicalRequest =
        sha256.convert(utf8.encode(CanonicalRequest)).toString().toLowerCase();
    String StringToSign =
        "$Algorithm\n$Timestamp\n$CredentialScope\n$HashedCanonicalRequest";

    var SecretDate = Hmac(sha256, utf8.encode("TC3$SecretKey"))
        .convert(utf8.encode(date))
        .bytes;
    var SecretService =
        Hmac(sha256, SecretDate).convert(utf8.encode("tmt")).bytes;
    var SecretSigning =
        Hmac(sha256, SecretService).convert(utf8.encode("tc3_request")).bytes;
    String Signature = Hmac(sha256, SecretSigning)
        .convert(utf8.encode(StringToSign))
        .toString()
        .toLowerCase();
    String Authorization =
        "$Algorithm Credential=$SecretId/$CredentialScope, SignedHeaders=$SignedHeaders, Signature=$Signature";
    Map<String, String> requestHeader = {
      "Host": "tmt.tencentcloudapi.com",
      "Content-Type": contentType,
      "X-TC-Version": "2018-03-21",
      "X-TC-Region": "ap-shanghai",
      "X-TC-Action": "TextTranslate",
      "X-TC-Timestamp": Timestamp,
      "Authorization": Authorization
    };
    var response = await http.post(Uri.parse("https://tmt.tencentcloudapi.com"),
        body: jsonRequestBody, headers: requestHeader);
    var utf8ResponseBody = utf8.decode(response.bodyBytes);
    Map<String, dynamic> responseBody = jsonDecode(utf8ResponseBody);
    print(responseBody);
    Map<String, dynamic> responseBody2 = responseBody["Response"];
    String result = responseBody2["TargetText"];
    return result;
  }
}
