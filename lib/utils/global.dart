import 'dart:convert';
import 'dart:typed_data';

import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget globalOutlinedButton({required VoidCallback onPressed, required String title}) {
  return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
alignment: Alignment.center,
          backgroundColor: Colors.indigo,
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(5.0)))),
      child: SizedBox.expand( child: Align(alignment: Alignment.center, child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ))));
}

Image imageFromBase64(String base64str, {double? width, double? height}) {
  Uint8List data = base64Decode(base64str);
  return Image.memory(data, width: width, height: height,);
}

Future<DateTime?> selectDate() async {
   return await showDatePicker(
      context: Prefs.navigatorKey.currentContext!,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)));
}

Future<TimeOfDay?> selectTime() async {
  return await showTimePicker(
      context: Prefs.navigatorKey.currentContext!, initialTime: TimeOfDay.now());
}

String durationToString(int i, String h, String m) {
  int hour = i ~/ 60;
  int min = i % 60;
  return '${hour>0 ? '$hour$h' : '' } ${min>0 ? '$min$m' : ''}';
}

DateTime strToDateTime(String dateTime) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
}

String dateTimeToStr(DateTime dateTime) {
  return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
}

String dateTimeToTimeStr(DateTime dateTime) {
  return DateFormat('HH:mm').format(dateTime);
}

String processDuration(String begin, int duration, String h, String m) {
  DateTime b = strToDateTime(begin);
  DateTime now = DateTime.now();
  Duration diff = now.difference(b);
  return durationToString(diff.inMinutes, h, m);
}

final RegExp doubleRegExp = RegExp(r'([.]*0)(?!.*\d)');

const kButtonHeight = 40.0;