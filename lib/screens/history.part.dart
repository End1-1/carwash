part of 'history.dart';

/// Первая колонка блока оплат в строке отчёта `cashsessions` (как `_payMethodByIndex`).
const int _kReportPaymentColumnBase = 11;

/// OGP в ответе `goods-in-progress/get`: `f_ogp_data` (раньше алиас `JSON_DETAILED(ogp.f_data)`).
const String _kOgpDataKeyLegacy = 'JSON_DETAILED(ogp.f_data)';

enum HistoryViewMode {
  report,
  goodsDoneParking,
}

enum HistoryGoodsPaymentFilter {
  all,
  unpaid,
  cash,
  card,
  idram,
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
  /// Для таблицы: к оплате (`f_amount_other`) или сумма заказа.
  final String amountLabel;
  /// То же число, что в [amountLabel], для строки «Итого» (0 если «—»).
  final double amountValue;
  /// Очередь ожидания после нормализации статусов (`1/1` → «Ожидает»).
  final bool isWaitingQueue;
  /// Из шапки для клиентского фильтра по способу оплаты.
  final double paidCash;
  final double paidCard;
  final double paidIdram;

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
    required this.amountLabel,
    required this.amountValue,
    required this.isWaitingQueue,
    required this.paidCash,
    required this.paidCard,
    required this.paidIdram,
  });
}

class HistoryModel {
  int sessionId = 0;
  String sessionTitle = '';
  /// Чтобы AppBar перерисовывал подпись смены без нового события [AppBloc].
  final sessionTitleListenable = ValueNotifier<String>('');
  final sessions = <Map<String, dynamic>>[];
  /// Строки SELECT из `form_cashsessions` — для клиентского фильтра и отображения.
  final reportRowsRaw = <List<dynamic>>[];
  /// Отфильтрованные 3/4 и 3/5 для табличного режима.
  final goodsRows = <HistoryGoodsRow>[];
  final viewMode = ValueNotifier(HistoryViewMode.report);
  /// Быстрый фильтр для «Готово / парковка» (клиент).
  final goodsPaymentFilter =
      ValueNotifier(HistoryGoodsPaymentFilter.all);
  /// То же для отчёта смены (`historyModeReport`).
  final reportPaymentFilter =
      ValueNotifier(HistoryGoodsPaymentFilter.all);
  /// Поиск по номеру авто на вкладке «Готово / парковка».
  final goodsCarSearchController = TextEditingController();

  HistoryModel({HistoryViewMode initialMode = HistoryViewMode.report}) {
    viewMode.value = initialMode;
    sessionId = prefs.getInt('cashsession') ?? 0;
    sessionTitleListenable.value =
        sessionId > 0 ? 'Session #$sessionId' : '';
    if (initialMode == HistoryViewMode.goodsDoneParking) {
      loadGoodsProcess();
    } else {
      loadLastSessions();
    }
  }

  /// Как в кассе: максимальный `value` в ответе `last-30-sessions` — последняя смена.
  int newestSessionIdFromLast30() {
    var best = 0;
    for (final e in sessions) {
      final v = int.tryParse('${e['value']}') ?? 0;
      if (v > best) best = v;
    }
    return best;
  }

  void loadLastSessions() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryShift(
        '/engine/v2/waiter/reports/last-30-sessions', <String, dynamic>{}));
  }

  void loadReport() {
    if (sessionId <= 0) {
      return;
    }
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
      final active = prefs.getInt('cashsession') ?? 0;
      if (active > 0) {
        _model.sessionId = active;
      } else if (_model.sessions.isNotEmpty) {
        _model.sessionId = _model.newestSessionIdFromLast30();
      } else {
        _model.sessionId = 0;
      }
      _updateSessionTitle();
      if (_model.sessionId > 0) {
        _model.loadReport();
      } else {
        _model.reportRowsRaw.clear();
      }
      return;
    }
    final rows = payload['rows'];
    if (rows is List) {
      _model.reportRowsRaw
        ..clear()
        ..addAll(rows.whereType<List>().map(List<dynamic>.from));
    }
  }

  bool _reportRowHasCash(List<dynamic> row) =>
      row.length > _kReportPaymentColumnBase &&
      _toMoney(row[_kReportPaymentColumnBase]) > 0.009;

  bool _reportRowHasCard(List<dynamic> row) =>
      row.length > _kReportPaymentColumnBase + 1 &&
      _toMoney(row[_kReportPaymentColumnBase + 1]) > 0.009;

  bool _reportRowHasIdram(List<dynamic> row) =>
      row.length > _kReportPaymentColumnBase + 3 &&
      _toMoney(row[_kReportPaymentColumnBase + 3]) > 0.009;

  double _reportRowTotal(List<dynamic> row) =>
      row.length > 10 ? _toMoney(row[10]) : 0;

  /// Нет сумм наличные / карта / Idram при ненулевом Total (прочее — банк, безнал и т.д.).
  bool _reportRowMatchesUnpaid(List<dynamic> row) {
    final total = _reportRowTotal(row);
    if (total <= 0.009) return false;
    return !_reportRowHasCash(row) &&
        !_reportRowHasCard(row) &&
        !_reportRowHasIdram(row);
  }

  List<List<dynamic>> _filteredReportRows(HistoryGoodsPaymentFilter f) {
    final source = _model.reportRowsRaw;
    switch (f) {
      case HistoryGoodsPaymentFilter.all:
        return List<List<dynamic>>.from(source);
      case HistoryGoodsPaymentFilter.unpaid:
        return source.where(_reportRowMatchesUnpaid).toList();
      case HistoryGoodsPaymentFilter.cash:
        return source.where(_reportRowHasCash).toList();
      case HistoryGoodsPaymentFilter.card:
        return source.where(_reportRowHasCard).toList();
      case HistoryGoodsPaymentFilter.idram:
        return source.where(_reportRowHasIdram).toList();
    }
  }

  double _sumReportRowsTotal(List<List<dynamic>> rows) {
    var s = 0.0;
    for (final r in rows) {
      if (r.length > 10) {
        s += _toMoney(r[10]);
      }
    }
    return s;
  }

  void handleGoodsProcessState(dynamic raw) {
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final items = _decodeProcessListRows(data);
    final merged = _groupProcessRowsByHeader(items)
      ..sort((a, b) {
        final byT =
            _sortKeyOrderTakenMs(a).compareTo(_sortKeyOrderTakenMs(b));
        if (byT != 0) return byT;
        return _headerKeyForRow(a).compareTo(_headerKeyForRow(b));
      });
    final l10n = AppLocalizations.of(prefs.context())!;
    final filtered = <HistoryGoodsRow>[];
    for (final row in merged) {
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

  /// Декодирует поле из API (строка JSON или уже `Map`). До 3 проходов — на случай
  /// двойного JSON-string от прокси/БД.
  Map<String, dynamic>? _parseJsonMapField(dynamic v) {
    if (v is Map) {
      try {
        return Map<String, dynamic>.from(v);
      } catch (_) {
        return null;
      }
    }
    if (v is! String || v.trim().isEmpty) return null;
    var s = v.trim();
    if (s.startsWith('\uFEFF')) s = s.substring(1);
    dynamic cur = s;
    for (var i = 0; i < 3; i++) {
      if (cur is Map) {
        try {
          return Map<String, dynamic>.from(cur);
        } catch (_) {
          return null;
        }
      }
      if (cur is! String) return null;
      try {
        cur = jsonDecode(cur.trim());
      } catch (_) {
        return null;
      }
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

  /// Как [migrate-html] `headerKeyForRow`: `f_header_id`, иначе `f_header`, иначе `f_id`.
  String _headerKeyForRow(Map<String, dynamic> row) {
    final v = row['f_header_id'] ?? row['f_header'];
    final s = v != null ? '$v'.trim() : '';
    if (s.isNotEmpty && s != '0') return 'h:$s';
    final id = '${row['f_id'] ?? ''}'.trim();
    return 'id:${id.isEmpty ? '0' : id}';
  }

  int _compareProcessLineIds(Map<String, dynamic> a, Map<String, dynamic> b) {
    final sa = '${a['f_id'] ?? ''}'.trim();
    final sb = '${b['f_id'] ?? ''}'.trim();
    final na = int.tryParse(sa);
    final nb = int.tryParse(sb);
    if (na != null && nb != null && na != nb) {
      return na.compareTo(nb);
    }
    return sa.compareTo(sb);
  }

  /// Момент времени для пары (st, ss) в `f_ogp_data` — см. migrate-html `ogpStatusSubTime`.
  String? _ogpStatusSubTime(Map<String, dynamic>? d, int st, int ss) {
    if (d == null) return null;
    final key = 'f_status_${st}_${ss}_time';
    dynamic v = d[key];
    if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    if (st == 1 && ss == 1) {
      v = d['f_status_1_time'];
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    if (st == 2 && ss == 2) {
      v = d['f_status_2_time'];
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    if (st == 2 && ss == 3) {
      v = d['f_status_3_time'] ?? d['f_status_2_time'];
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    if (st == 3 && ss == 4) {
      v = d['f_status_4_time'] ?? d['f_status_3_time'];
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    if (st == 3 && ss == 5) {
      v = d['f_status_3_time'] ?? d['f_parking_time'] ?? d['f_status_5_time'];
      if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
    }
    return null;
  }

  double _timeMsFromOgpRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) return double.infinity;
    final s = raw.trim();
    var d = DateTime.tryParse(s);
    if (d == null) {
      d = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    }
    if (d == null) return double.infinity;
    return d.millisecondsSinceEpoch.toDouble();
  }

  double _pendingQueueTimeMs(Map<String, dynamic> row) {
    final ogp = _ogpDataStrict(row);
    final raw = _ogpStatusSubTime(ogp, 1, 1);
    return _timeMsFromOgpRaw(raw);
  }

  double _inProgressEnteredAtMs(Map<String, dynamic> row) {
    final st = _processStatus(row);
    final ss = _resolvedSubstatus(row);
    if (st == null || ss == null) return double.infinity;
    final ogp = _ogpDataStrict(row);
    final raw = _ogpStatusSubTime(ogp, st, ss);
    return _timeMsFromOgpRaw(raw);
  }

  /// Время «взятия» заказа: очередь 1/1 — по времени постановки; иначе — вход в текущий статус.
  double _sortKeyOrderTakenMs(Map<String, dynamic> row) {
    final q = _pendingQueueTimeMs(row);
    if (q.isFinite) return q;
    final p = _inProgressEnteredAtMs(row);
    if (p.isFinite) return p;
    return double.infinity;
  }

  Map<String, dynamic> _pickPrimaryPending(List<Map<String, dynamic>> lines) {
    Map<String, dynamic>? best;
    var bestT = double.infinity;
    for (final line in lines) {
      final t = _pendingQueueTimeMs(line);
      if (t < bestT) {
        bestT = t;
        best = line;
      }
    }
    return best ?? lines.first;
  }

  Map<String, dynamic> _pickPrimaryInProgress(List<Map<String, dynamic>> lines) {
    Map<String, dynamic>? best;
    var bestT = double.infinity;
    for (final line in lines) {
      final t = _inProgressEnteredAtMs(line);
      if (t < bestT) {
        bestT = t;
        best = line;
      }
    }
    return best ?? lines.first;
  }

  /// Очередь 1/1 — как `pickPrimaryPending`; иначе как `pickPrimaryInProgress` (migrate-html).
  Map<String, dynamic> _pickPrimaryMerged(List<Map<String, dynamic>> lines) {
    final allPending = lines.every((r) {
      final st = _processStatus(r);
      if (st != 1) return false;
      final ss = _resolvedSubstatus(r);
      return ss == null || ss == 1;
    });
    if (allPending) {
      return _pickPrimaryPending(lines);
    }
    return _pickPrimaryInProgress(lines);
  }

  String _combinedServiceNames(List<Map<String, dynamic>> lines) {
    final parts = <String>[];
    for (final line in lines) {
      final name = '${line['f_name'] ?? ''}'.trim();
      if (name.isNotEmpty) parts.add(name);
    }
    return parts.isEmpty ? '—' : parts.join('\n');
  }

  /// Несколько строк `o_goods_process` с одним шапочным id — одна строка таблицы (как `groupRowsByHeader` в migrate-html).
  List<Map<String, dynamic>> _groupProcessRowsByHeader(
    List<Map<String, dynamic>> items,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    final keyOrder = <String>[];
    for (final r in items) {
      final k = _headerKeyForRow(r);
      if (!map.containsKey(k)) {
        keyOrder.add(k);
        map[k] = <Map<String, dynamic>>[];
      }
      map[k]!.add(r);
    }
    final out = <Map<String, dynamic>>[];
    for (final k in keyOrder) {
      final lines = map[k]!;
      if (lines.length == 1) {
        out.add(lines.single);
        continue;
      }
      final sorted = List<Map<String, dynamic>>.from(lines)
        ..sort(_compareProcessLineIds);
      final primary = _pickPrimaryMerged(sorted);
      final merged = Map<String, dynamic>.from(primary);
      merged['f_name'] = _combinedServiceNames(sorted);
      out.add(merged);
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

  /// Шапка заказа: в ответе `goods-in-progress/get` это `f_header_data` — по сути
  /// `o_header.f_data` (оплаты, номер, фискал). Полный `o_goods.f_data` по строкам
  /// корзины этим запросом не отдаётся; время готовки берётся отдельным полем SQL.
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
    if (other > 0.009) return true;

    final cash = _money(hdr['f_amount_cash'] ?? hdr['f_amountcash']);
    final card = _money(hdr['f_amount_card'] ?? hdr['f_amountcard']);
    final idram = _money(hdr['f_amount_idram'] ?? hdr['f_amountidram']);
    final paid = cash + card + idram;

    final subTotal = _money(hdr['f_sub_total'] ?? hdr['f_subtotal']);
    final total = _money(hdr['f_amounttotal'] ?? hdr['f_amount_total']);
    final orderTotal = subTotal > 0.009 ? subTotal : total;

    // Legacy rows can miss f_amount_other and all payment fields in f_data:
    // treat them as unpaid full amount to keep payment available in history.
    if (orderTotal > 0.009 && paid <= 0.009) return true;

    return false;
  }

  String _formatMoneyTable(double v) {
    if (v == v.roundToDouble()) return '${v.round()}';
    return v.toStringAsFixed(2);
  }

  /// Число для колонки «Сумма» и для итога: «прочее», иначе сумма заказа.
  double _amountValueFromHeader(Map<String, dynamic> hdr) {
    final other = _money(hdr['f_amount_other'] ?? hdr['f_amountother']);
    if (other > 0.009) return other;
    final subTotal = _money(hdr['f_sub_total'] ?? hdr['f_subtotal']);
    if (subTotal > 0.009) return subTotal;
    final total = _money(hdr['f_amounttotal'] ?? hdr['f_amount_total']);
    if (total > 0.009) return total;
    return 0;
  }

  /// В колонке «Сумма»: неоплаченный остаток по «прочее», иначе сумма заказа.
  String _amountLabelFromHeader(Map<String, dynamic> hdr) {
    final v = _amountValueFromHeader(hdr);
    if (v <= 0.009) return '—';
    return '${_formatMoneyTable(v)} ֏';
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

  /// Как в migrate-html: 1/1, 2/2, 2/3, 3/4, 3/5.
  bool _isKnownProcessPair(int st, int ss) {
    if (st == 1 && ss == 1) return true;
    if (st == 2 && (ss == 2 || ss == 3)) return true;
    if (st == 3 && (ss == 4 || ss == 5)) return true;
    return false;
  }

  /// Если `f_status` и `f_ogp_data.f_substatus` расходятся (частый случай 2/4),
  /// подстатусы 4 и 5 относятся только к `f_status == 3`.
  (int?, int?) _normalizedProcessStatusSubstatus(Map<String, dynamic> row) {
    final st = _processStatus(row);
    final ss = _resolvedSubstatus(row);
    if (st == null || ss == null) return (st, ss);
    if (_isKnownProcessPair(st, ss)) return (st, ss);
    if (st < 3 && (ss == 4 || ss == 5)) return (3, ss);
    return (st, ss);
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
    final (st, ss) = _normalizedProcessStatusSubstatus(row);
    if (st == 1 && ss == 1) return l10n.pending;
    if (st == 2 && ss == 2) return l10n.historyStatusWash;
    if (st == 2 && ss == 3) return l10n.historyStatusDry;
    if (st == 3 && ss == 4) return l10n.historyStatusFreeParking;
    if (st == 3 && ss == 5) return l10n.historyStatusPaidParking;
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
    final (st, ss) = _normalizedProcessStatusSubstatus(row);
    final statusLabel = _statusLabelForRow(row, l10n);
    final canPay = _canPayFromHeader(hdr);
    final paymentLabel = _paymentLabelFromHeader(hdr, l10n);
    final amountLabel = _amountLabelFromHeader(hdr);
    final amountValue = _amountValueFromHeader(hdr);
    final paidCash = _money(hdr['f_amount_cash'] ?? hdr['f_amountcash']);
    final paidCard = _money(hdr['f_amount_card'] ?? hdr['f_amountcard']);
    final paidIdram = _money(hdr['f_amount_idram'] ?? hdr['f_amountidram']);
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
      amountLabel: amountLabel,
      amountValue: amountValue,
      isWaitingQueue: st == 1 && ss == 1,
      paidCash: paidCash,
      paidCard: paidCard,
      paidIdram: paidIdram,
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
    // 0:id, 1:session, 2:prefix, 3:hall, 4:table, 5:car, 6:open, 7:close, 8:staff,
    // 9:cashier, 10:total, 11..N-2:payments, N-1:service
    final openDate = row.length > 6 ? '${row[6] ?? ''}'.trim() : '';
    final carRaw = row.length > 5 ? '${row[5] ?? ''}'.trim() : '';
    final car = carRaw.isEmpty ? '—' : carRaw;
    final orderCodeRaw = row.length > 2 ? '${row[2] ?? ''}'.trim() : '';
    final orderCode = orderCodeRaw.isEmpty
        ? (row.isNotEmpty ? '${row[0] ?? ''}'.trim() : '')
        : orderCodeRaw;

    final total = row.length > 10 ? '${row[10] ?? ''}'.trim() : '0';
    final payStart = 11;
    final payEndExclusive = row.length > 12 ? row.length - 1 : row.length;
    final methods = <String>[];
    for (var i = payStart; i < payEndExclusive; i++) {
      final amount = _toMoney(row[i]);
      if (amount > 0.009) {
        methods.add(_payMethodByIndex(i - payStart));
      }
    }
    final methodLabel = methods.isEmpty ? '-' : methods.join('+');
    return '$openDate | $car | $total ($methodLabel) | $orderCode';
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
    final v = _model.sessionTitle;
    // Не вызывать notifyListeners смены из build [BlocBuilder] в body — post-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_model.sessionTitleListenable.value != v) {
        _model.sessionTitleListenable.value = v;
      }
    });
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
    } else if (_model.sessionId <= 0) {
      _model.loadLastSessions();
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
