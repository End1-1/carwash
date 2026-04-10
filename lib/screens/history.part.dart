part of 'history.dart';

/// OGP в ответе `goods-in-progress/get`: `f_ogp_data` (раньше алиас `JSON_DETAILED(ogp.f_data)`).
const String _kOgpDataKeyLegacy = 'JSON_DETAILED(ogp.f_data)';

enum HistoryViewMode {
  report,
  goodsDoneParking,
}

class HistoryGoodsRow {
  final String car;
  final String service;
  final String daily;
  final String statusLabel;
  /// `f_header_id` (`oh.f_id`) для QueryOrder / ModifyOrder.
  final String orderId;
  /// `ogp.f_header` / `oh.f_id` для отмены заказа.
  final String headerId;
  final int? processStatus;
  final int? processSubstatus;
  final bool canPay;
  final String paymentLabel;

  HistoryGoodsRow({
    required this.car,
    required this.service,
    required this.daily,
    required this.statusLabel,
    required this.orderId,
    required this.headerId,
    required this.processStatus,
    required this.processSubstatus,
    required this.canPay,
    required this.paymentLabel,
  });
}

class HistoryModel {
  int sessionId = 0;
  String sessionTitle = '';
  final sessions = <Map<String, dynamic>>[];
  final printing = <String>[];
  /// Отфильтрованные 3/4 и 3/5 для табличного режима.
  final goodsRows = <HistoryGoodsRow>[];
  final viewMode = ValueNotifier(HistoryViewMode.report);

  HistoryModel({HistoryViewMode initialMode = HistoryViewMode.report}) {
    viewMode.value = initialMode;
    if (initialMode == HistoryViewMode.goodsDoneParking) {
      loadGoodsProcess();
    } else {
      loadLastSessions();
    }
  }

  void loadLastSessions() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryShift(
        '/engine/v2/waiter/reports/last-30-sessions', <String, dynamic>{}));
  }

  void loadReport() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryShift(
        '/engine/v2/officen/editors/get-all',
        <String, dynamic>{
          'editor': 'form_cashsessions',
          'filter': <Map<String, dynamic>>[
            {'date1': _date(DateTime.now().subtract(const Duration(days: 30)))},
            {'date2': _date(DateTime.now())},
            {'session_id': sessionId},
          ],
        }));
  }

  void loadGoodsProcess() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryGoodsProcess(
        '/engine/v2/carwash/goods-in-progress/get',
        <String, dynamic>{
          'f_menu': int.tryParse(prefs.string('menucode')) ?? 0,
        }));
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

extension HistoryE on HistoryScreen {
  void handleReportsState(dynamic raw) {
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final payload = _payload(data);
    final values = payload['values'];
    if (values is List) {
      _model.sessions
        ..clear()
        ..addAll(values.map((e) => Map<String, dynamic>.from(e as Map)));
      if (_model.sessionId <= 0 && _model.sessions.isNotEmpty) {
        _model.sessionId = int.tryParse('${_model.sessions.first['value']}') ?? 0;
      }
      _updateSessionTitle();
      _model.loadReport();
      return;
    }
    final rows = payload['rows'];
    if (rows is List) {
      final visible = <String>[];
      for (final r in rows) {
        if (r is List) {
          visible.add(_compactHistoryRow(r));
        }
      }
      _model.printing
        ..clear()
        ..addAll(visible);
    }
  }

  void handleGoodsProcessState(dynamic raw) {
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final items = _decodeProcessListRows(data);
    final l10n = AppLocalizations.of(prefs.context())!;
    final filtered = <HistoryGoodsRow>[];
    for (final row in items) {
      filtered.add(_goodsDisplayRow(row, l10n));
    }
    _model.goodsRows
      ..clear()
      ..addAll(filtered);
  }

  bool _apiStatusOk(dynamic status) {
    if (status == 1 || status == true) return true;
    if (status is num && status.toInt() == 1) return true;
    final s = '$status'.trim().toLowerCase();
    return s == '1' || s == 'true';
  }

  /// Тело ответа: `result.data` — массив строк SELECT (см. `GoodsInProgress::get`).
  List<Map<String, dynamic>> _decodeProcessListRows(Map<String, dynamic> json) {
    if (!_apiStatusOk(json['status'])) return [];
    final data = json['data'];
    if (data is! List) return [];
    return _normalizeRowList(data);
  }

  Map<String, dynamic>? _parseJsonMapField(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String && v.isNotEmpty) {
      try {
        final d = jsonDecode(v);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return null;
  }

  List<Map<String, dynamic>> _normalizeRowList(List list) {
    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is Map) out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  Map<String, dynamic>? _ogpDataStrict(Map<String, dynamic> row) {
    final primary = row['f_ogp_data'];
    if (primary != null) {
      final m = _parseJsonMapField(primary);
      if (m != null && m.isNotEmpty) return m;
    }
    return _parseJsonMapField(row[_kOgpDataKeyLegacy]);
  }

  /// `JSON_DETAILED(oh.f_data) AS f_header_data`
  Map<String, dynamic>? _headerDataStrict(Map<String, dynamic> row) {
    return _parseJsonMapField(row['f_header_data']);
  }

  // NOTE: раньше в этом экране показывались только 3/4 и 3/5 (и только «неоплачено»),
  // но теперь показываем все статусы без фильтра.

  double _money(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(' ', '').replaceAll(',', '').trim()) ?? 0;
  }

  String _paymentLabelFromHeader(Map<String, dynamic> hdr, AppLocalizations l10n) {
    final cash = _money(hdr['f_amount_cash'] ?? hdr['f_amountcash']);
    final card = _money(hdr['f_amount_card'] ?? hdr['f_amountcard']);
    final idram = _money(hdr['f_amount_idram'] ?? hdr['f_amountidram']);
    final other = _money(hdr['f_amount_other'] ?? hdr['f_amountother']);
    final methods = <String>[];
    if (cash > 0.009) methods.add(l10n.cash);
    if (card > 0.009) methods.add(l10n.card);
    if (idram > 0.009) methods.add(l10n.idram);
    if (other > 0.009) methods.add(l10n.other);
    if (methods.isEmpty) return '—';
    return methods.join(' + ');
  }

  bool _canPayFromHeader(Map<String, dynamic> hdr) {
    final other = _money(hdr['f_amount_other'] ?? hdr['f_amountother']);
    return other > 0.009;
  }

  int? _processStatus(Map<String, dynamic> row) =>
      int.tryParse('${row['f_status']}');

  int? _resolvedSubstatus(Map<String, dynamic> row) {
    final st = _processStatus(row);
    if (st == null) return null;
    final ogp = _ogpDataStrict(row);
    if (ogp == null) return null;
    final ss = ogp['f_substatus'];
    if (ss != null && '$ss'.isNotEmpty) {
      return int.tryParse('$ss');
    }
    if (st == 1) return 1;
    return null;
  }

  /// `oh.f_id AS f_header_id`
  String? _headerOrderId(Map<String, dynamic> row) {
    final v = row['f_header'] ?? row['f_header_id'];
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty || s == '0') return null;
    return s;
  }

  String? _headerIdForCancel(Map<String, dynamic> row) {
    final direct = row['f_header'] ?? row['f_header_id'];
    final s = direct != null ? '$direct'.trim() : '';
    if (s.isNotEmpty && s != '0') return s;
    final ogp = _ogpDataStrict(row);
    final v2 = ogp?['f_header'];
    final s2 = v2 != null ? '$v2'.trim() : '';
    if (s2.isNotEmpty && s2 != '0') return s2;
    return null;
  }

  String _statusLabelForRow(
    Map<String, dynamic> row,
    AppLocalizations l10n,
  ) {
    final st = _processStatus(row);
    final ss = _resolvedSubstatus(row);
    if (st == 1 && ss == 1) return l10n.pending;
    if (st == 3 && ss == 4) return l10n.historyStatusDone;
    if (st == 3 && ss == 5) return l10n.historyStatusParking;
    if (st != null && ss != null) return '$st/$ss';
    if (st != null) return '$st';
    return '—';
  }

  HistoryGoodsRow _goodsDisplayRow(
    Map<String, dynamic> row,
    AppLocalizations l10n,
  ) {
    final hdr = _headerDataStrict(row) ?? {};
    var car = '${hdr['f_car_number'] ?? ''}'.trim();
    if (car.isEmpty) car = '—';
    var service = '${row['f_name'] ?? ''}'.trim();
    if (service.isEmpty) service = '—';
    final daily = '${row['f_daily_number'] ?? ''}'.trim();
    final st = _processStatus(row);
    final ss = _resolvedSubstatus(row);
    final statusLabel = _statusLabelForRow(row, l10n);
    final canPay = _canPayFromHeader(hdr);
    final paymentLabel = _paymentLabelFromHeader(hdr, l10n);
    return HistoryGoodsRow(
      car: car,
      service: service,
      daily: daily.isEmpty ? '—' : daily,
      statusLabel: statusLabel,
      orderId: _headerOrderId(row) ?? '',
      headerId: _headerIdForCancel(row) ?? '',
      processStatus: st,
      processSubstatus: ss,
      canPay: canPay,
      paymentLabel: paymentLabel,
    );
  }

  Map<String, dynamic> _payload(Map<String, dynamic> data) {
    final d = data['data'];
    if (d is Map) {
      return Map<String, dynamic>.from(d);
    }
    return data;
  }

  String _compactHistoryRow(List row) {
    // cashsessions.php SELECT layout:
    // 0:id, 1:session, 2:order(prefix), 5:open-datetime, 9:total, 10..N-2:payments, N-1:service
    final openDate = row.length > 5 ? '${row[5] ?? ''}'.trim() : '';
    final orderCodeRaw = row.length > 2 ? '${row[2] ?? ''}'.trim() : '';
    final orderCode = orderCodeRaw.isEmpty
        ? (row.isNotEmpty ? '${row[0] ?? ''}'.trim() : '')
        : orderCodeRaw;

    final total = row.length > 9 ? '${row[9] ?? ''}'.trim() : '0';
    final payStart = 10;
    final payEndExclusive = row.length > 11 ? row.length - 1 : row.length;
    final methods = <String>[];
    for (var i = payStart; i < payEndExclusive; i++) {
      final amount = _toMoney(row[i]);
      if (amount > 0.009) {
        methods.add(_payMethodByIndex(i - payStart));
      }
    }
    final methodLabel = methods.isEmpty ? '-' : methods.join('+');
    return '$openDate | $total ($methodLabel) | $orderCode';
  }

  double _toMoney(dynamic v) {
    if (v == null) return 0;
    final s = v
        .toString()
        .replaceAll(' ', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(s) ?? 0;
  }

  String _payMethodByIndex(int idx) {
    switch (idx) {
      case 0:
        return 'Cash';
      case 1:
        return 'Card';
      case 2:
        return 'Bank';
      case 3:
        return 'Idram';
      case 4:
        return 'Complimentary';
      case 5:
        return 'Other';
      default:
        return 'Pay';
    }
  }

  void _updateSessionTitle() {
    final row = _model.sessions.firstWhere(
      (e) => int.tryParse('${e['value']}') == _model.sessionId,
      orElse: () => <String, dynamic>{},
    );
    final text = '${row['text'] ?? ''}'.trim();
    _model.sessionTitle = text.isEmpty ? 'Session #${_model.sessionId}' : text;
  }

  void chooseSession() {
    if (_model.viewMode.value != HistoryViewMode.report) return;
    if (_model.sessions.isEmpty) {
      _model.loadLastSessions();
      return;
    }
    final variants = _model.sessions.map((e) => '${e['text'] ?? ''}').toList();
    BlocProvider.of<QuestionBloc>(prefs.context()).add(QuestionEventList(variants, (idx) {
      if (idx < 0 || idx >= _model.sessions.length) return;
      _model.sessionId = int.tryParse('${_model.sessions[idx]['value']}') ?? 0;
      _updateSessionTitle();
      refreshReport();
    }));
  }

  void refreshReport() {
    if (_model.viewMode.value == HistoryViewMode.goodsDoneParking) {
      _model.loadGoodsProcess();
    } else {
      _model.loadReport();
    }
  }
}

void _normalizePayAmountsMap(Map<String, dynamic> o) {
  double mn(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '').trim()) ?? 0;
  }

  final total = mn(o['f_amounttotal']);
  var cash = mn(o['f_amountcash']);
  var card = mn(o['f_amountcard']);
  var idram = mn(o['f_amountidram']);
  var other = mn(o['f_amountother']);
  if (cash + card + idram + other < 0.01) {
    other = total;
  }
  o['f_amountcash'] = cash;
  o['f_amountcard'] = card;
  o['f_amountidram'] = idram;
  o['f_amountother'] = other;
}

Future<void> openGoodsPayForHistory(HistoryScreen screen, HistoryGoodsRow row) async {
  if (row.orderId.isEmpty) {
    Dialogs.show(screen.model.locale().historyPayMissingOrderId);
    return;
  }
  final m = screen.model;
  final ctx = prefs.context();
  await Loading.showUntilDisplayed(m.locale().loading);
  Map<String, dynamic>? order;
  try {
    order = await m.fetchOrderForPayment(row.orderId);
  } finally {
    Loading.dismiss();
  }
  if (order == null) {
    Dialogs.show(m.locale().historyPayGetOrderFailed);
    return;
  }
  final o = Map<String, dynamic>.from(order);
  _normalizePayAmountsMap(o);
  final payPs = row.processStatus;
  final payPss = row.processSubstatus;
  m.printFiscal = true;
  final ok = await showDialog<bool>(
    context: ctx,
    builder: (dctx) => AlertDialog(
      title: Text(m.locale().historyPayTitle),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 520,
          child: HistoryPayDialogBody(
            model: m,
            orderMap: o,
            headerId: row.orderId,
            processStatus: payPs,
            processSubstatus: payPss,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx),
          child: Text(m.locale().cancel),
        ),
      ],
    ),
  );
  if (ok == true) {
    screen.reloadGoodsProcess();
  }
}

Future<void> cancelOrderForHistory(HistoryScreen screen, HistoryGoodsRow row) async {
  final id = row.headerId.trim();
  if (id.isEmpty) {
    Dialogs.show(screen.model.locale().historyPayMissingOrderId);
    return;
  }
  final m = screen.model;
  final l10n = m.locale();
  final confirm = await Dialogs.question('${l10n.cancel}?', m);
  if (confirm != true) return;

  await Loading.showUntilDisplayed(l10n.loading);
  String? errorText;
  try {
    final r = await WebHttpQuery('/engine/v2/waiter/order/cancelation')
        .request(<String, dynamic>{'id': id});
    if (r['status'] == 1 || r['status'] == true) {
      screen.reloadGoodsProcess();
      return;
    }
    errorText = '${r['data'] ?? 'Cancelation failed'}';
  } catch (e) {
    errorText = e.toString();
  } finally {
    Loading.dismiss();
  }
  if (errorText.trim().isNotEmpty) {
    await Dialogs.show(errorText);
  }
}
