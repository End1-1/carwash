import 'dart:convert';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


class WebHttpQuery {

  final String route;
  WebHttpQuery(this.route);

  Future<Map<String, dynamic>> request(Map<String, dynamic> inData) async {
    inData.forEach((key, value) {
      if (value is DateTime) {
        inData[key] = DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
      }
    });
    inData['apikey'] = prefs.string("apikey");
    inData['apikey'] ='8eabcee4-f1bc-11ee-8b0f-021eaa527a65-a0d5c784-f1bc-11ee-8b0f-021eaa527a65';
    inData['config'] = prefs.string('config');
    inData['language'] = 'am';

    Map<String, Object?> outData = {};
    String strBody = jsonEncode(inData);
    if (kDebugMode) {
      print('${prefs.string("webserveraddress")}$route');
      print('request: $strBody');
    }
    try {
      var response = await http
          .post(
          Uri.https('${prefs.string("webserveraddress")}', route),
          headers: {
            'Content-Type': 'application/json',
            //'Content-Length': '${utf8.encode(strBody).length}'
            // "Access-Control-Allow-Origin": "*",
            // "Access-Control-Allow-Methods": "GET,PUT,PATCH,POST,DELETE",
            // "Access-Control-Allow-Headers":
            //     "Origin, X-Requested-With, Content-Type, Accept"
          },
          body: utf8.encode(strBody))
          .timeout(const Duration(seconds: 120), onTimeout: () {
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
