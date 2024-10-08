import 'dart:convert';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


class HttpQuery2 {
  static const String networkdb = 'networkdb';
  static const String printfiscal = 'printfiscal';
  static const String printbill= 'printbill';

  final String route;
  HttpQuery2(this.route);

  Future<Map<String, dynamic>> request(Map<String, dynamic> inData) async {
    if (inData['params'] == null) {
      inData['params'] = <String, dynamic>{};
    }
    inData['key'] = 'asd666649888d!!jjdjmskkak98983mj???m';
    inData['params']!['apikey'] = prefs.string("apikey");
    inData['config'] = prefs.string('config');
    inData['language'] = 'am';

    Map<String, Object?> outData = {};
    String strBody = jsonEncode(inData);
    if (kDebugMode) {
      print('request: $strBody');
    }
    try {
      var response = await http
          .post(
              Uri.https('${prefs.string("serveraddress")}:10002', route),
              headers: {
                'Content-Type': 'application/json',
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
