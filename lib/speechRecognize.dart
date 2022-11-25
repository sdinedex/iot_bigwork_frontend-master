// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class SpeechRecognize {
  static Future<String> recognize(String uri, String type) async {
    var dateTime = DateTime.now().toUtc();
    var date = "${dateTime.year}-${dateTime.month}-${dateTime.day}";
    var Timestamp = dateTime.millisecondsSinceEpoch.toString().substring(0, 10);
    var Algorithm = "TC3-HMAC-SHA256";
    var CredentialScope = "$date/asr/tc3_request";
    String SecretKey = "Ulqma9C5mGWhkkfOtBYuBKGxPi5Tipmj";
    String SecretId = "AKIDxkIbjfOvG4f17zhCRSFmDMPK3Zu1uZ9i";

    String HTTPRequestMethod = "POST";
    String CanonicalURI = "/";
    String CanonicalQueryString = "";
    String contentType = "application/json; charset=utf-8";
    String CanonicalHeaders =
        "content-type:$contentType\nhost:asr.tencentcloudapi.com\n";
    String SignedHeaders = "content-type;host";
    var requestBody = {
      "UsrAudioKey": "test", //废弃
      "SubServiceType": 2,
      "Url": uri,
      "ProjectId": 0, //废弃
      "EngSerViceType": type == "chinese" ? "16k_zh" : "16k_en",
      "VoiceFormat": "aac",
      "SourceType": 0
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
        Hmac(sha256, SecretDate).convert(utf8.encode("asr")).bytes;
    var SecretSigning =
        Hmac(sha256, SecretService).convert(utf8.encode("tc3_request")).bytes;
    String Signature = Hmac(sha256, SecretSigning)
        .convert(utf8.encode(StringToSign))
        .toString()
        .toLowerCase();
    String Authorization =
        "$Algorithm Credential=$SecretId/$CredentialScope, SignedHeaders=$SignedHeaders, Signature=$Signature";
    Map<String, String> requestHeader = {
      "Host": "asr.tencentcloudapi.com",
      "Content-Type": contentType,
      "X-TC-Version": "2019-06-14",
      "X-TC-Region": "ap-shanghai",
      "X-TC-Action": "SentenceRecognition",
      "X-TC-Timestamp": Timestamp,
      "Authorization": Authorization
    };
    var response = await http.post(Uri.parse("https://asr.tencentcloudapi.com"),
        body: jsonRequestBody, headers: requestHeader);
    var utf8ResponseBody = utf8.decode(response.bodyBytes);
    Map<String, dynamic> responseBody = jsonDecode(utf8ResponseBody);
    Map<String, dynamic> responseBody2 = responseBody["Response"];
    String result = responseBody2["Result"];
    return result;
  }
}
