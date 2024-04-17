// ignore_for_file: avoid_print, body_might_complete_normally_nullable

import 'dart:convert';

import 'package:d_method/d_method.dart';
import 'package:http/http.dart' as http;

class AppRequest {
  static const apiKey = "";
  static Future<Map?> gets(String url, {Map<String, String>? headers}) async {
    try {
      var resHttpGet = await http.get(Uri.parse(url), headers: headers);
      DMethod.printTitle("Try ~ $url", resHttpGet.body);
      if (resHttpGet.statusCode == 200) {
        DMethod.printTitle(
            "Try ~ $url : success", resHttpGet.statusCode.toString());
        print("status code: ${resHttpGet.statusCode}");
        Map? resGetToMap = jsonDecode(resHttpGet.body);
        return resGetToMap;
      } else if (resHttpGet.statusCode == 400) {
        DMethod.printTitle("Try ~ $url : data tidak ditemukan",
            resHttpGet.statusCode.toString());
        print("status code: ${resHttpGet.statusCode}");
        return null;
      } else if (resHttpGet.statusCode == 500) {
        DMethod.printTitle(
            "Try ~ $url : Terjadi kesalahan internal pada server",
            resHttpGet.statusCode.toString());
        print("status code: ${resHttpGet.statusCode}");
        return null;
      }
    } catch (error) {
      DMethod.printTitle("Catch From AppRequest ~ ", error.toString());
      return null;
    }
  }

  static Future<Map?> posts(String url, Object? body,
      {Map<String, String>? headers}) async {
    try {
      var resHttpPost =
          await http.post(Uri.parse(url), body: body, headers: headers);

      if (resHttpPost.statusCode == 200) {
        Map? resPostToMap = jsonDecode(resHttpPost.body);
        return resPostToMap;
      } else if (resHttpPost.statusCode == 400) {
        DMethod.printTitle("Try ~ $url : data tidak ditemukan",
            resHttpPost.statusCode.toString());
        print("status code: ${resHttpPost.statusCode}");
        return null;
      } else if (resHttpPost.statusCode == 500) {
        DMethod.printTitle(
            "Try ~ $url : Terjadi kesalahan internal pada server",
            resHttpPost.statusCode.toString());
        print("status code: ${resHttpPost.statusCode}");
        return null;
      }
    } catch (error) {
      DMethod.printTitle("Catch From AppRequest ~ ", error.toString());
      return null;
    }
  }
}
