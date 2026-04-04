import 'dart:convert';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io' show Platform;

/// Убирает сегмент пути `/apps` (сервер ожидает URL без него). Не трогает `…myapps…`.
String normalizeWebApiRoute(String route) {
  var r = route.trim();
  if (r.isEmpty) return r;
  var prev = '';
  while (prev != r) {
    prev = r;
    r = r.replaceFirst(RegExp(r'/apps(?=/|$)'), '');
  }
  while (r.contains('//')) {
    r = r.replaceAll('//', '/');
  }
  if (r.isEmpty) return '/';
  if (!r.startsWith('/')) r = '/$r';
  return r;
}

class WebHttpQuery {

  final String route;
  final int timeoutSeconds;
  WebHttpQuery(String route, {this.timeoutSeconds = 10})
      : route = normalizeWebApiRoute(route);

  Future<Map<String, dynamic>> request(Map<String, dynamic> inData) async {
    inData.forEach((key, value) {
      if (value is DateTime) {
        inData[key] = DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
      }
    });
    inData['config'] = prefs.string('config');
    inData['language'] = 'am';
    inData['hostinfo'] = Platform.localHostname;
    inData['cashsession'] = prefs.getInt('cashsession') ?? 0;
    inData["nootp"] = true;

    Map<String, Object?> outData = {};
    String strBody = jsonEncode(inData);
    final host = prefs.string('webserveraddress');
    final useSsl = prefs.string('usessl').toUpperCase() != 'NO';
    final uri =
        useSsl ? Uri.https(host, route) : Uri.http(host, route);
    if (kDebugMode) {
      print('$uri');
      print('request: $strBody');
    }
    try {
      var response = await http
          .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Application-Name': 'carwash',
            'X-Application-Version': '1.0.2',
            'Authorization': 'Bearer ${prefs.string('token')}',
            //'Content-Length': '${utf8.encode(strBody).length}'
            // "Access-Control-Allow-Origin": "*",
            // "Access-Control-Allow-Methods": "GET,PUT,PATCH,POST,DELETE",
            // "Access-Control-Allow-Headers":
            //     "Origin, X-Requested-With, Content-Type, Accept"
          },
          body: utf8.encode(strBody))
          .timeout(Duration(seconds: timeoutSeconds), onTimeout: () {
        return http.Response('Timeout', 408);
      });
      String strResponse = utf8.decode(response.bodyBytes);
      if (kDebugMode) {
        print('Row body $strResponse');
      }
      if (response.statusCode < 299) {
        try {
          outData = jsonDecode(strResponse);
          if (!outData.containsKey('status')) {
            outData['status'] = 0;
            if (!outData.containsKey('data')) {
              outData['data'] = jsonEncode(outData);
            }
          }
        } catch (e) {
          outData['status'] = 0;
          outData['data'] = '${e.toString()} $strResponse';
        }
      } else {
        outData['status'] = 0;
        outData['data'] = strResponse;
      }
    } catch (e) {
      outData['status'] = 0;
      outData['data'] = e.toString();
    }
    if (kDebugMode) {
      print('Output $outData');
    }
    return outData;
  }
}
