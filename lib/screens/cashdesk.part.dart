part of 'cashdesk.dart';

class CashdeskModel {
  String reportName = '';
  int reportId = 1;
  int sessionId = 0;
  String sessionTitle = '';
  final sessions = <Map<String, dynamic>>[];
  final printing = <String>[];
  int reportRequestNo = 0;
  int lastPrintedRequestNo = 0;

  CashdeskModel() {
    print("DDDD");
    loadReportList();
  }

  void onEnter() {
    // Prevent showing stale report lines from previous screen visit.
    printing.clear();
    if (sessionId > 0) {
      refreshReport();
    } else {
      loadReportList();
    }
  }

  void loadReportList() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryShift(
        '/engine/v2/waiter/reports/get-list', <String, dynamic>{}));
  }

  void loadLastSessions() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryShift(
        '/engine/v2/waiter/reports/last-30-sessions', <String, dynamic>{}));
  }

  void loadReport() {
    if (sessionId <= 0) {
      return;
    }
    reportRequestNo++;
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryShift(
        '/engine/v2/waiter/reports/get-report',
        <String, dynamic>{
          'report_id': reportId,
          'report_name': reportName,
          'params': <String, dynamic>{
            'session_id': sessionId,
          }
        }));
  }

  void closeDay(model) {
    final cid = model.cashboxIdForOrder;
    if (cid <= 0) {
      Dialogs.show(model.locale().cashboxNotConfigured);
      return;
    }
    BlocProvider.of<QuestionBloc>(prefs.context()).add(
      QuestionEventRaise('Փակել ակտիվ դրամարկղի հերթափոխը՞', () {
        BlocProvider.of<AppBloc>(prefs.context()).add(
          AppEventQueryCloseDay(
            '/engine/v2/waiter/cashbox/close',
            <String, dynamic>{'cashbox_id': cid},
          ),
        );
      }, () {}),
    );
  }

  void handleReportsState(model, dynamic raw) {
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw as Map);
    final list = data['list'];
    if (list is List && list.isNotEmpty && reportName.isEmpty) {
      final first = Map<String, dynamic>.from(list.first as Map);
      reportId = int.tryParse('${first['report_id']}') ?? 1;
      reportName = '${first['title'] ?? ''}';
      final dv = first['default_values'];
      if (dv is Map && sessionId <= 0) {
        sessionId = int.tryParse('${dv['session_id']}') ?? 0;
      }
      loadLastSessions();
      return;
    }
    final values = data['values'];
    if (values is List) {
      sessions
        ..clear()
        ..addAll(values.map((e) => Map<String, dynamic>.from(e as Map)));
      if (sessionId <= 0 && sessions.isNotEmpty) {
        sessionId = int.tryParse('${sessions.first['value']}') ?? 0;
      }
      _updateSessionTitle();
      loadReport();
      return;
    }
    final p = data['printing'];
    if (p is List) {
      if (lastPrintedRequestNo != reportRequestNo) {
        lastPrintedRequestNo = reportRequestNo;
        unawaited(model.sendRawPrintCommands(
          printData: List<dynamic>.from(p),
          showLoadingDialog: false,
        ));
      }
      final visible = <String>[];
      for (final e in p) {
        final line = _renderPrintCmd(Map<String, dynamic>.from(e as Map));
        if (line.isNotEmpty) visible.add(line);
      }
      printing
        ..clear()
        ..addAll(visible);
    }
  }

  void _updateSessionTitle() {
    final row = sessions.firstWhere(
      (e) => int.tryParse('${e['value']}') == sessionId,
      orElse: () => <String, dynamic>{},
    );
    final text = '${row['text'] ?? ''}'.trim();
    sessionTitle = text.isEmpty ? 'Session #$sessionId' : text;
  }

  String _renderPrintCmd(Map<String, dynamic> cmd) {
    final c = '${cmd['cmd'] ?? ''}';
    if (c == 'lrtext') {
      return '${cmd['left'] ?? ''} ${cmd['right'] ?? ''}'.trim();
    }
    if (c == 'ctext' || c == 'ltext' || c == 'rtext') {
      return '${cmd['text'] ?? ''}'.trim();
    }
    return '';
  }

  void chooseSession() {
    if (sessions.isEmpty) {
      loadLastSessions();
      return;
    }
    final variants = sessions.map((e) => '${e['text'] ?? ''}').toList();
    BlocProvider.of<QuestionBloc>(prefs.context()).add(QuestionEventList(variants, (idx) {
      if (idx < 0 || idx >= sessions.length) return;
      sessionId = int.tryParse('${sessions[idx]['value']}') ?? 0;
      _updateSessionTitle();
      refreshReport();
    }));
  }

  void refreshReport() {
    loadReport();
  }
}
