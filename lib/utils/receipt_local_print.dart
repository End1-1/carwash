import 'dart:convert';

import 'package:carwash/l10n/app_localizations.dart';
import 'package:carwash/utils/posprint.dart';
import 'package:intl/intl.dart';

/// Суммы: разделитель тысяч, без лишних дробных нулей (до 2 знаков после запятой).
final NumberFormat _sumFmt = NumberFormat('#,##0.##', 'en_US');

String _formatSum(num? v) {
  if (v == null) return '0';
  final n = v.toDouble();
  if (n.isNaN || n.isInfinite) return '0';
  return _sumFmt.format(n);
}

/// Проценты: без лишних нулей после запятой.
final NumberFormat _pctFmt = NumberFormat('0.##', 'en_US');

String _formatPct(num? v) {
  if (v == null) return '0';
  final n = v.toDouble();
  if (n.isNaN || n.isInfinite) return '0';
  return _pctFmt.format(n);
}

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String _fieldStr(Map<String, dynamic> m, Object key) {
  final v = m[key];
  if (v == null) return '';
  final s = v.toString().trim();
  return s;
}

List<Map<String, dynamic>> _orderLines(Map<String, dynamic> order) {
  final v = order['dishes'];
  if (v is List) {
    return v
        .map((e) =>
            e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
        .toList();
  }
  return [];
}

Map<String, dynamic>? _parseFiscalBlock(Map<String, dynamic> order) {
  final f = order['fiscal'];
  if (f is Map) return Map<String, dynamic>.from(f);
  return null;
}

Map<String, dynamic>? _mergeFiscal(
  Map<String, dynamic> order,
  Map<String, dynamic>? explicit,
) {
  if (explicit != null && explicit.isNotEmpty) return explicit;
  return _parseFiscalBlock(order);
}

Map<String, dynamic>? _orderFDataMap(Map<String, dynamic> order) {
  final fd = order['f_data'];
  if (fd is String && fd.isNotEmpty) {
    try {
      final d = jsonDecode(fd);
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
  } else if (fd is Map) {
    return Map<String, dynamic>.from(fd);
  }
  return null;
}

/// Поля сумм в том же порядке, что C++ `payment_fields` (PAYMENT_TYPE_* → QString).
/// Индексы 0…5 должны совпадать с enum на сервере.
const List<String> _paymentAmountFieldsLikeCpp = [
  'f_amount_cash',
  'f_amount_card',
  'f_amount_bank',
  'f_amount_idram',
  'f_amount_complimentary',
  'f_amount_other',
];

/// Строго ключ `f_car_number` внутри `order['f_data']`.
String _carFromFDataOnly(Map<String, dynamic>? fdm) {
  if (fdm == null) return '';
  final v = fdm['f_car_number'];
  if (v == null) return '';
  return v.toString().trim();
}

/// Строго ключ `f_payment_type` (int, как PAYMENT_TYPE_* в C++).
String _paymentLabelFromFData(AppLocalizations loc, Map<String, dynamic>? fdm) {
  if (fdm == null) return '';
  final raw = fdm['f_payment_type'];
  if (raw == null) return '';
  final t = raw is int ? raw : int.tryParse(raw.toString());
  if (t == null || t < 0 || t >= _paymentAmountFieldsLikeCpp.length) {
    return '';
  }
  switch (t) {
    case 0:
      return loc.cash;
    case 1:
      return loc.card;
    case 2:
      return loc.receiptPaymentBank;
    case 3:
      return loc.idram;
    case 4:
      return loc.receiptPaymentComplimentaryShort;
    case 5:
      return loc.other;
    default:
      return '';
  }
}

/// Сборка предчека в [PosPrint] (команды для `print_data`).
Future<void> buildReceiptToCmdBuffer({
  required PosPrint p,
  required Map<String, dynamic> order,
  Map<String, dynamic>? fiscalTax,
  required AppLocalizations loc,
  required String staffName,
}) async {
  const bs = 10.0;
  p.fontsize(bs);

  final st = order['f_state'];
  final preorder = st == 2;
  late final String titleLine;
  if (preorder) {
    titleLine = loc.receiptPreorder;
  } else if (st == 1 || st == 3) {
    titleLine = loc.receiptTitle;
  } else if (st != null) {
    titleLine = '${loc.receiptErrorState} ($st)';
  } else {
    titleLine = loc.receiptTitle;
  }

  final receiptNo = '${order['f_receipt_number'] ?? ''}'.trim();
  if (receiptNo.isNotEmpty) {
    p.lrtext(titleLine, receiptNo);
  } else {
    p.ltext(titleLine);
  }
  p.br();

  final jtax = _mergeFiscal(order, fiscalTax);
  if (jtax != null && jtax.isNotEmpty) {
    void taxPair(String left, String right) {
      final r = right.trim();
      p.lrtext(left, r.isEmpty ? null : r);
      p.br();
    }

    final tp = '${jtax['taxpayer'] ?? ''}'.trim();
    if (tp.isNotEmpty) {
      p.ltext(tp);
      p.br();
    }
    final addr = '${jtax['address'] ?? ''}'.trim();
    if (addr.isNotEmpty) {
      p.ltext(addr);
      p.br();
    }
    taxPair(loc.receiptTin, '${jtax['tin'] ?? ''}');
    taxPair(loc.receiptDeviceNumber, '${jtax['crn'] ?? ''}');
    taxPair(loc.receiptSerial, '${jtax['sn'] ?? ''}');
    taxPair(loc.receiptFiscal, '${jtax['fiscal'] ?? ''}');
    final rseq = jtax['rseq'];
    taxPair(loc.receiptReceiptNumber, rseq == null ? '' : '$rseq');
    final t = _num(jtax['time']);
    if (t != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.round());
      taxPair(loc.date, DateFormat('yyyy-MM-dd HH:mm:ss').format(dt));
    }
    p.ltext(loc.receiptFMarker);
    p.br();
  }

  final hall = '${order['f_hall_name'] ?? ''}'.trim();
  final table = '${order['f_table_name'] ?? ''}'.trim();
  final hallTable =
      '$hall${table.isNotEmpty && hall.isNotEmpty ? '/' : ''}$table';
  p.lrtext(loc.tableField, hallTable.trim().isEmpty ? null : hallTable);
  p.br();
  p.lrtext(
    loc.receiptStaff,
    staffName.trim().isEmpty ? null : staffName,
  );
  p.br();
  final fdm = _orderFDataMap(order);
  final carNum = _carFromFDataOnly(fdm);
  if (carNum.isNotEmpty) {
//    p.br(height: 0);
   p.fontsize(bs + 4);
    p.ctext(carNum);
 //   p.br(height: 5);
    p.fontsize(bs );
  }
  final payStr = _paymentLabelFromFData(loc, fdm);
  if (payStr.isNotEmpty) {
    p.lrtext(loc.receiptPaymentMethod, payStr);
    p.br();
  }
  p.br();
  //p.line2(2);
  p.br();

  p.fontsize(bs);

  p.ltext(loc.receiptNameCol, x: 0, width:  35);
  p.ltext(loc.receiptQtyCol, x: 36, width: 10);
  p.ltext(loc.price, x: 46, width: 15);
  p.rtext(loc.amount);
  p.br();
  p.line2(2);
  p.br();

  var noservice = false;
  var nodiscount = false;
  var complimentary = false;

  final lines = _orderLines(order);
  for (final dish in lines) {
    if (dish['f_state'] != 1) continue;

    p.fontsize(bs);
    final adg = '${dish['f_adg_code'] ?? ''}'.trim();
    if (adg.isNotEmpty) {
      p.ltext('${loc.receiptClass}: $adg');
      p.br();
    }

    var name = '${dish['f_dish_name'] ?? ''}';

    final countSvc = dish['f_count_service'];
    if (countSvc == false || countSvc == 0 || countSvc == '0') {
      noservice = true;
      name += '* ';
    }
    final countDisc = dish['f_count_discount'];
    if (countDisc == false || countDisc == 0 || countDisc == '0') {
      nodiscount = true;
      name += '** ';
    }
    final comp = dish['f_complimentary'];
    if (comp == true || comp == 1 || comp == '1') {
      complimentary = true;
      name += '*** ';
    }

    final qty = _num(dish['f_qty']);
    final price = _num(dish['f_price']);
    final total = _num(dish['f_total']);

    p.ltext(name, x: 0, width:  35);
    p.ltext(_formatSum(qty), x: 36, width: 10);
    p.ltext(_formatSum(price), x: 46, width: 15);
    p.rtext(_formatSum(total));
    p.br();
    p.line();
    //p.br();
  }

  p.fontsize(bs - 2);
  if (noservice) {
    p.ltext(loc.receiptNoService.toLowerCase());
    p.br();
  }
  if (nodiscount) {
    p.ltext(loc.receiptNoDiscount.toLowerCase());
    p.br();
  }
  if (complimentary) {
    p.ltext(loc.receiptComplimentary.toLowerCase());
    p.br();
  }

  p.fontsize(bs + 2);
  p.lrtext(
    loc.receiptSubtotal,
    _formatSum(_num(order['f_amounttotal'])),
  );
  p.br();

  final svc = _num(order['f_service_factor']);
  if (svc != null && svc > 0) {
    p.fontsize(bs);
    p.lrtext(loc.receiptService, '+${_formatPct(svc * 100)}%');
    p.br();
  }

  final disc = _num(order['f_discount_factor']);
  if (disc != null && disc > 0) {
    p.fontsize(bs);
    p.lrtext(loc.receiptDiscount, '-${_formatPct(disc * 100)}%');
    p.br();
  }

  final prepaid = _num(order['f_prepaid_amount']);
  if (prepaid != null && prepaid > 0.01) {
    p.fontsize(bs);
    p.lrtext(loc.receiptPrepaid, _formatSum(prepaid * -1));
    p.br();
  }

  p.br();

  void payLine(String label, double amt) {
    if (amt > 0.01) {
      p.lrtext(label, _formatSum(amt));
      p.br();
    }
  }

  final ordData = jsonDecode(order['f_data'] ?? '');

  payLine(loc.cash, _num(ordData['f_amount_cash']) ?? 0);
  payLine(loc.card, _num(ordData['f_amount_card']) ?? 0);
  payLine(loc.idram, _num(ordData['f_amount_idram']) ?? 0);
  payLine(loc.other, _num(ordData['f_amount_other']) ?? 0);

  final totalDue = _num(order['f_total_due']);
  final paid = _num(order['f_amount_paid']);
  if (paid != null &&
      totalDue != null &&
      paid - totalDue > 0.01) {
    p.br();
    p.lrtext(loc.receiptAmountPaid, _formatSum(paid));
    p.br();
    p.lrtext(loc.receiptChange, _formatSum(paid - totalDue));
    p.br();
  }

  p.br();
  p.fontsize(bs - 2);
  p.ltext(loc.receiptThankYou);
  p.br();

  final printCount = order['f_print_count'];
  final openOrClose = st == 1 || st == 3;
  if (printCount != null && openOrClose) {
    p.ltext('${loc.receiptSample}: $printCount');
  }

  p.br();
  p.lrtext(loc.receiptPrinted, DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));
  p.br();
}

/// Список команд для POST на `print_server` (поле `print_data` в JSON).
Future<List<Map<String, dynamic>>> buildReceiptPrintCmdList({
  required Map<String, dynamic> order,
  Map<String, dynamic>? fiscalTax,
  required AppLocalizations loc,
  required String staffName,
}) async {
  final p = PosPrint();
  await buildReceiptToCmdBuffer(
    p: p,
    order: order,
    fiscalTax: fiscalTax,
    loc: loc,
    staffName: staffName,
  );
  return p.toCommandList();
}
