import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

/// Ответ ККМ может содержать мусор после закрывающей `}` — вырезаем один JSON-объект с начала строки.
String? extractLeadingJsonObject(String s) {
  final t = s.trim();
  final start = t.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  for (var j = start; j < t.length; j++) {
    final ch = t[j];
    if (ch == '{') {
      depth++;
    } else if (ch == '}') {
      depth--;
      if (depth == 0) {
        return t.substring(start, j + 1);
      }
    }
  }
  return null;
}

/// Убирает управляющие символы в конце (например `\b`), мешающие [jsonDecode].
String stripTrailingControlGarbage(String s) {
  return s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]+$'), '');
}

Map<String, dynamic>? tryParseFiscalJson(String raw) {
  var t = stripTrailingControlGarbage(raw.trim());
  if (t.isEmpty) return null;
  Object? v;
  try {
    v = jsonDecode(t);
  } catch (_) {
    final slice = extractLeadingJsonObject(t);
    if (slice == null) return null;
    try {
      v = jsonDecode(slice);
    } catch (_) {
      return null;
    }
  }
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

/// Тестовый «успешный» ответ ККМ (аналог Qt `outOutJson` с подставляемым [rseq]).
Map<String, dynamic> simulatedFiscalOutJson([int? rseq]) {
  final seq = rseq ?? (DateTime.now().millisecondsSinceEpoch % 10000000);
  return {
    'address': 'ԿԵՆՏՐՈՆ ԹԱՂԱՄԱՍ Ամիրյան 4/3 ',
    'change': 0.0,
    'crn': '53235782',
    'fiscal': '54704153',
    'lottery': '',
    'prize': 0,
    'rseq': seq,
    'sn': '00022154380',
    'taxpayer': '«ՊԼԱԶԱ ՍԻՍՏԵՄՍ»',
    'time': 1709630105632,
    'tin': '02596277',
    'total': 93600.0,
  };
}

/// Результат печати (как в Qt: `in` / `out` JSON для `close-order` и `fiscal-log`).
class FiscalPrintResult {
  final Map<String, dynamic> inJson;
  final Map<String, dynamic>? outJson;
  final String error;
  /// 0 — успех (как в C++ `pt_err_ok` после печати); иначе код ККМ или отрицательный сокет.
  final int result;

  const FiscalPrintResult({
    required this.inJson,
    this.outJson,
    this.error = '',
    this.result = 0,
  });

  bool get isOk => result == 0;
}

class PrintTaxN {
  /// Если `true`, при любой ошибке сокета/ККМ возвращается успех с [simulatedFiscalOutJson].
  var  isDEBUG = true;
  final String ip;
  final int port;
  final String password;
  final String taxCashier;
  final String taxPin;
  final String useExtPos;

  static const int opcodeLogin = 2;
  static const int opcodeLogout = 3;
  static const int opcodePrintReceipt = 4;

  final Uint8List _firstData =
      Uint8List.fromList([213, 128, 212, 180, 213, 132, 0, 5, 2, 0, 0, 0]);

  List<Map<String, dynamic>> fJsonGoods = [];
  List<String> fEmarks = [];
  String? fPartnerTin;

  PrintTaxN({
    required this.ip,
    required this.port,
    required this.password,
    this.taxCashier = '3',
    this.taxPin = '3',
    this.useExtPos = 'false'
  }) {
    if (!kDebugMode) {
      isDEBUG = false;
    }
  }

  void clearGoods() {
    fJsonGoods.clear();
    fEmarks.clear();
    fPartnerTin = null;
  }

  void addGoods({
    required int dep,
    required String adgCode,
    required int productCode,
    required String name,
    required double price,
    required double qty,
    double discount = 0,
  }) {
    final item = <String, dynamic>{
      'dep': dep,
      'adgCode': adgCode,
      'productCode': productCode,
      'productName': name.replaceAll('"', r'\"'),
      'price': price,
      'qty': qty,
      'unit': 'հատ',
    };
    if (discount > 0.01) {
      item['discount'] = discount;
      item['discountType'] = 1;
    }
    fJsonGoods.add(item);
  }

  Uint8List _process3DES(Uint8List key, Uint8List data, bool encrypt) {
    Uint8List paddedData;
    if (encrypt) {
      final padLen = 8 - (data.length % 8);
      paddedData = Uint8List(data.length + padLen);
      paddedData.setAll(0, data);
      paddedData.fillRange(data.length, paddedData.length, padLen);
    } else {
      paddedData = data;
    }

    final cipher = ECBBlockCipher(DESedeEngine())
      ..init(encrypt, KeyParameter(key));

    final out = Uint8List(paddedData.length);
    for (var i = 0; i < paddedData.length; i += 8) {
      cipher.processBlock(paddedData, i, out, i);
    }

    if (!encrypt && out.isNotEmpty) {
      final padLen = out.last;
      if (padLen <= 8 && padLen <= out.length) {
        return out.sublist(0, out.length - padLen);
      }
    }
    return out;
  }

  Uint8List _makeHeader(int opcode, int dataLen) {
    final header = Uint8List.fromList([..._firstData]);
    header[8] = opcode;
    // C++ writes dataLen bytes as big-endian into dst[10]/dst[11].
    ByteData.view(header.buffer).setUint16(10, dataLen, Endian.big);
    return header;
  }

  static int _statusFromHeader(Uint8List h) {
    if (h.length < 7) return -1;
    return ByteData.sublistView(h, 5, 7).getUint16(0, Endian.big);
  }

  static int _bodyLenFromHeader(Uint8List h) {
    if (h.length < 9) return 0;
    return ByteData.sublistView(h, 7, 9).getUint16(0, Endian.big);
  }

  /// Тело чека как Map (аналог строки до `printJSON` в Qt) — для `fiscal.in`.
  Map<String, dynamic> buildReceiptRequestMap({
    required double cash,
    required double card,
    required double prepaid,
  }) {
    final items = <Map<String, dynamic>>[];
    for (final g in fJsonGoods) {
      final row = <String, dynamic>{
        'adgCode': g['adgCode'],
        'dep': g['dep'],
        'price': g['price'],
        'productCode': g['productCode'] is int
            ? g['productCode']
            : int.tryParse('${g['productCode']}') ?? 0,
        'productName': g['productName'],
        'qty': g['qty'],
        'unit': g['unit'] ?? 'հատ',
      };
      if (g.containsKey('discount')) {
        row['discount'] = g['discount'];
        row['discountType'] = g['discountType'] ?? 1;
      }
      items.add(row);
    }

    final map = <String, dynamic>{
      'seq': 1,
      'paidAmount': cash,
      'paidAmountCard': card,
      'partialAmount': 0,
      'prePaymentAmount': prepaid,
      'useExtPOS': useExtPos.toLowerCase() == 'true',
      'mode': 2,
      'partnerTin': fPartnerTin,
      'items': items,
    };
    if (fEmarks.isNotEmpty) {
      map['eMarks'] = fEmarks;
    }
    return map;
  }

  Future<FiscalPrintResult> printReceiptWithDetails({
    required double cash,
    required double card,
    required double prepaid,
    void Function(String message)? onStep,
  }) async {
    final inJson = buildReceiptRequestMap(
      cash: cash,
      card: card,
      prepaid: prepaid,
    );

    late final Socket socket;
    try {
      onStep?.call('Fiscal: connect ${ip}:${port}…');
      socket = await Socket.connect(ip, port,
          timeout: const Duration(seconds: 2));
      onStep?.call('Fiscal: connected');
    } catch (e) {
      onStep?.call('Fiscal: connection failed: $e');
      if (isDEBUG) {
        return FiscalPrintResult(
          inJson: inJson,
          outJson: simulatedFiscalOutJson(),
          error: '',
          result: 0,
        );
      }
      return FiscalPrintResult(
        inJson: inJson,
        error: 'Connection: $e',
        result: -2,
      );
    }

    // Buffered socket reader (more deterministic than repeated `socket.first`).
    final buf = <int>[];
    Completer<void>? waiter;
    final sub = socket.listen(
      (chunk) {
        buf.addAll(chunk);
        if (waiter != null && !waiter!.isCompleted) {
          waiter!.complete();
        }
      },
      onError: (e) {
        if (waiter != null && !waiter!.isCompleted) {
          waiter!.completeError(e);
        }
      },
      cancelOnError: false,
    );

    Future<Uint8List> take(int n) async {
      while (buf.length < n) {
        waiter = Completer<void>();
        await waiter!.future;
      }
      final out = Uint8List.fromList(buf.sublist(0, n));
      buf.removeRange(0, n);
      return out;
    }

    // По вашей логике:
    // - 130s только когда `useExtPos=false` и платим картой (нужно время приложить карту)
    // - иначе таймаут можно сократить.
    final useExtPosBool = useExtPos.toLowerCase() == 'true';
    final cardPay = card > 0.01;
    final Duration readTimeout =
        (!useExtPosBool && cardPay) ? const Duration(seconds: 130) : const Duration(seconds: 15);
    Future<Uint8List> takeWithTimeout(int n, String what) async {
      try {
        onStep?.call('Fiscal: waiting $what…');
        return await take(n).timeout(readTimeout);
      } on TimeoutException catch (_) {
        onStep?.call('Fiscal: $what timeout after ${readTimeout.inSeconds}s');
        rethrow;
      }
    }

    try {
      final masterKey = Uint8List.fromList(
          sha256.convert(utf8.encode(password)).bytes.sublist(0, 24));

      final cashier = int.tryParse(taxCashier) ?? 3;
      final pin = int.tryParse(taxPin) ?? 3;
      final loginData = jsonEncode({
        'password': password,
        'cashier': cashier,
        'pin': pin,
      });
      final encLogin = _process3DES(masterKey, Uint8List.fromList(utf8.encode(loginData)), true);

      onStep?.call('Fiscal: send login…');
      socket.add(_makeHeader(opcodeLogin, encLogin.length));
      socket.add(encLogin);
      onStep?.call('Fiscal: flush login…');
      await socket.flush().timeout(const Duration(seconds: 30));
      onStep?.call('Fiscal: login request sent');

      var hdr = await takeWithTimeout(11, 'login header (11 bytes)');
      var code = _statusFromHeader(hdr);
      var blen = _bodyLenFromHeader(hdr);
      var body = await takeWithTimeout(blen, 'login body ($blen bytes)');
      if (code != 200) {
        onStep?.call('Fiscal: login failed code=$code');
        if (isDEBUG) {
          return FiscalPrintResult(
            inJson: inJson,
            outJson: simulatedFiscalOutJson(),
            error: '',
            result: 0,
          );
        }
        return FiscalPrintResult(
          inJson: inJson,
          error: 'Login failed, code $code',
          result: code,
        );
      }
      onStep?.call('Fiscal: login ok');

      final decSession = _process3DES(masterKey, body, false);
      Map<String, dynamic> sessionObj;
      try {
        final sessionStr = stripTrailingControlGarbage(utf8.decode(decSession));
        final parsed = tryParseFiscalJson(sessionStr);
        if (parsed == null) {
          throw FormatException('Session JSON');
        }
        sessionObj = parsed;
      } catch (e) {
        if (isDEBUG) {
          return FiscalPrintResult(
            inJson: inJson,
            outJson: simulatedFiscalOutJson(),
            error: '',
            result: 0,
          );
        }
        return FiscalPrintResult(
          inJson: inJson,
          error: 'Session JSON: $e',
          result: 105,
        );
      }
      final sessionKey = base64Decode(sessionObj['key'] as String);

      final receiptStr = jsonEncode(inJson);
      final encReceipt =
          _process3DES(sessionKey, Uint8List.fromList(utf8.encode(receiptStr)), true);

      onStep?.call('Fiscal: send print receipt…');
      socket.add(_makeHeader(opcodePrintReceipt, encReceipt.length));
      socket.add(encReceipt);
      onStep?.call('Fiscal: flush print receipt…');
      await socket.flush().timeout(const Duration(seconds: 30));
      onStep?.call('Fiscal: print receipt request sent');

      hdr = await takeWithTimeout(11, 'print header (11 bytes)');
      code = _statusFromHeader(hdr);
      blen = _bodyLenFromHeader(hdr);
      body = await takeWithTimeout(blen, 'print body ($blen bytes)');
      if (code != 200) {
        onStep?.call('Fiscal: print failed code=$code');
        if (isDEBUG) {
          return FiscalPrintResult(
            inJson: inJson,
            outJson: simulatedFiscalOutJson(),
            error: '',
            result: 0,
          );
        }
        return FiscalPrintResult(
          inJson: inJson,
          error: 'Print failed, code $code',
          result: code,
        );
      }
      onStep?.call('Fiscal: print ok');

      final decOut = _process3DES(sessionKey, body, false);
      Map<String, dynamic>? outMap;
      final outStr = stripTrailingControlGarbage(utf8.decode(decOut).trim());
      if (outStr.isNotEmpty) {
        outMap = tryParseFiscalJson(outStr);
        if (outMap == null && isDEBUG) {
          outMap = simulatedFiscalOutJson();
        } else if (outMap == null) {
          outMap = {'raw': utf8.decode(decOut)};
        }
      }

      final logoutPlain = jsonEncode({'seq': 2});
      final encLogout = _process3DES(
          masterKey, Uint8List.fromList(utf8.encode(logoutPlain)), true);
      onStep?.call('Fiscal: send logout…');
      socket.add(_makeHeader(opcodeLogout, encLogout.length));
      socket.add(encLogout);
      onStep?.call('Fiscal: flush logout…');
      await socket.flush().timeout(const Duration(seconds: 30));
      onStep?.call('Fiscal: logout sent');

      return FiscalPrintResult(
        inJson: inJson,
        outJson: outMap,
        result: 0,
      );
    } catch (e) {
      onStep?.call('Fiscal: exception: $e');
      if (isDEBUG) {
        return FiscalPrintResult(
          inJson: inJson,
          outJson: simulatedFiscalOutJson(),
          error: '',
          result: 0,
        );
      }
      return FiscalPrintResult(
        inJson: inJson,
        error: e.toString(),
        result: -3,
      );
    } finally {
      await sub.cancel();
      socket.destroy();
    }
  }
}
