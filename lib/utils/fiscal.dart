import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dart_des/dart_des.dart';
import 'package:encrypt/encrypt.dart';

class Fiscal {
  static const jsonIn = <String, dynamic>{
    "items": [
      {
        "adgCode": "45.20",
        "dep": 1,
        "price": 1,
        "productCode": "1",
        "productName": "Հիմնական լվացում",
        "qty": 1,
        "totalPrice": 1,
        "unit": "հատ"
      }
    ],
    "mode": 2,
    "paidAmount": 1,
    "paidAmountCard": 0,
    "partialAmount": 0,
    "partnerTin": null,
    "prePaymentAmount": 0,
    "seq": 1,
    "useExtPOS": false
  };

  late Socket socket;
  final String fiscalMachineHost;
  final int fiscalMachinePort;
  final String fiscalMachinePassword;
  final String fiscalMachineOpCode;
  final String fiscalMachineOpPin;
  var errorString = '';

  Fiscal(
      {required this.fiscalMachineHost,
      required this.fiscalMachinePort,
      required this.fiscalMachinePassword,
       required this.fiscalMachineOpCode, required this.fiscalMachineOpPin, });

  Future<bool> connectToHost() async {
    try {
      socket = await Socket.connect(fiscalMachineHost, fiscalMachinePort);
    } catch (e) {
      errorString = e.toString();
    }
    return errorString.isEmpty;
  }

  void cryptedData() async {
    var bytes = utf8.encode(fiscalMachinePassword);
    var digest = sha256.convert(bytes);
    var sha256str = digest.toString().substring(0, 24);
    var authStr = '{"password":"$fiscalMachinePassword","cashier":$fiscalMachineOpCode,"pin":"$fiscalMachineOpPin"}';

    final Key key = Key.fromUtf8(sha256str);
    final IV iv = IV.fromLength(0);


    DES3 desECB = DES3(key:  sha256str.codeUnits, mode: DESMode.ECB, iv: DES.IV_ZEROS);
    List<int> cryptedAuthData = desECB.encrypt(authStr.codeUnits);

    Uint16 strLen = cryptedAuthData.length as Uint16;
    ByteData strLenBytes = ByteData(2);
    strLenBytes.setInt16(0, strLen as int);

    int opCodeLogin = 2;
    Uint8List header = Uint8List(12);
    Uint8List firstData = Uint8List.fromList([213, 128, 212, 180, 213, 132, 0, 5, opCodeLogin, 0, strLenBytes.getInt8(1), strLenBytes.getInt8(0)]);
    header.addAll(firstData);

    socket.write(header);
    socket.write(cryptedAuthData);

    socket.listen(listenAuth);
  }

  void listenAuth(dynamic d) {

  }
}
