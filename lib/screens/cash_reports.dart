import 'dart:async';

import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/kbd.dart';
import 'package:carwash/utils/numpad_money_string.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/utils/web_query.dart';
import 'package:carwash/widgets/app_nav_popup_menu.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:carwash/widgets/loading.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:carwash/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CashReportsModel {
  static const int reportId = 5;
  static const String reportName = 'Касса';

  int sessionId = 0;
  final sessions = <Map<String, dynamic>>[];
  final printing = <String>[];
  List<dynamic>? _lastPrintPayload;
  static const String _line = '────────────────────────';

  void onEnter() {
    printing.clear();
    _lastPrintPayload = null;
    loadLastSessions();
  }

  int _newestSessionIdFromLast30() {
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
    if (sessionId <= 0) return;
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

  void handleState(dynamic raw) {
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw as Map);
    final values = data['values'];
    if (values is List) {
      sessions
        ..clear()
        ..addAll(values.map((e) => Map<String, dynamic>.from(e as Map)));
      if (sessionId <= 0 && sessions.isNotEmpty) {
        sessionId = _newestSessionIdFromLast30();
      }
      loadReport();
      return;
    }
    final p = data['printing'];
    if (p is List) {
      _lastPrintPayload = List<dynamic>.from(p);
      final visible = <String>[];
      for (final e in p) {
        if (e is! Map) continue;
        final cmd = Map<String, dynamic>.from(e);
        final c = '${cmd['cmd'] ?? ''}';
        if (c == 'br') continue;
        if (c == 'line' || c == 'line2') {
          if (visible.isNotEmpty && visible.last == _line) continue;
          visible.add(_line);
          continue;
        }
        if (c == 'lrtext') {
          final left = '${cmd['left'] ?? ''}'.trim();
          final right = '${cmd['right'] ?? ''}'.trim();
          if (left.isEmpty && right.isEmpty) continue;
          if (left.isEmpty) {
            visible.add(right);
          } else if (right.isEmpty || right == 'null') {
            visible.add(left);
          } else {
            visible.add('$left: $right');
          }
          continue;
        }
        if (c == 'ctext' || c == 'ltext' || c == 'rtext') {
          final text = '${cmd['text'] ?? ''}'.trim();
          if (text.isNotEmpty) visible.add(text);
        }
      }
      printing
        ..clear()
        ..addAll(visible);
    }
  }

  void chooseSession() {
    if (sessions.isEmpty) {
      loadLastSessions();
      return;
    }
    final variants = sessions.map((e) => '${e['text'] ?? ''}').toList();
    BlocProvider.of<QuestionBloc>(prefs.context())
        .add(QuestionEventList(variants, (idx) {
      if (idx < 0 || idx >= sessions.length) return;
      sessionId = int.tryParse('${sessions[idx]['value']}') ?? 0;
      loadReport();
    }));
  }

  bool get hasPrintPayload =>
      _lastPrintPayload != null && _lastPrintPayload!.isNotEmpty;

  void printLastReport(AppModel model) {
    final p = _lastPrintPayload;
    if (p == null || p.isEmpty) return;
    unawaited(model.sendRawPrintCommands(
      printData: List<dynamic>.from(p),
      showLoadingDialog: true,
    ));
  }

  Future<void> openMoveMoney(AppModel model) async {
    final cashboxId = model.cashboxIdForOrder;
    if (cashboxId <= 0) {
      Dialogs.show(model.locale().cashboxNotConfigured);
      return;
    }
    if (sessionId <= 0) {
      Dialogs.show(model.locale().noActiveSession);
      return;
    }
    final payload = await showDialog<Map<String, dynamic>>(
      context: prefs.context(),
      builder: (_) => _CashMoveMoneyDialog(sessionId: sessionId),
    );
    if (payload == null) return;

    await Loading.showUntilDisplayed(model.locale().loading);
    String? errorText;
    try {
      final r =
          await WebHttpQuery('/engine/v2/waiter/cashbox/move-money').request(
        <String, dynamic>{
          'cashbox_id': cashboxId,
          'f_order_id': payload['f_order_id'] ?? 0,
          'f_payment_type_id': payload['f_payment_type_id'] ?? 1,
          'f_debit': payload['f_debit'] ?? 0,
          'f_credit': payload['f_credit'] ?? 0,
          'f_currency_id': payload['f_currency_id'] ?? 1,
          'f_comment': payload['f_comment'] ?? '',
        },
      );
      if (r['status'] == 1 || r['status'] == true) {
        loadReport();
      } else {
        errorText = '${r['data'] ?? model.locale().cashMoveMoneyFailed}';
      }
    } catch (e) {
      errorText = '$e';
    } finally {
      Loading.dismiss();
    }
    if (errorText != null && errorText!.trim().isNotEmpty) {
      Dialogs.show(errorText!);
    }
  }
}

class CashReportsScreen extends AppScreen {
  static final _model = CashReportsModel();

  CashReportsScreen(super.model, {super.key}) {
    _model.onEnter();
  }

  static Future<void> syncSessionAndApplyFilter(AppModel model) async {
    await model.syncCashboxSessionFromApi();
    final sid = prefs.getInt('cashsession') ?? 0;
    _model.sessionId = sid > 0 ? sid : 0;
  }

  @override
  PreferredSizeWidget appBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.home_outlined),
        onPressed: model.navHome,
      ),
      backgroundColor: Colors.green,
      toolbarHeight: kToolbarHeight,
      title: Text(model.locale().cashReports),
      actions: [
        IconButton(
            onPressed: _model.chooseSession,
            icon: const Icon(Icons.list_alt_outlined)),
        Container(
            alignment: Alignment.center,
            width: 120,
            child: Text(
              _model.sessionId > 0 ? 'Session #${_model.sessionId}' : '',
            )),
        IconButton(
            onPressed: () => _model.openMoveMoney(model),
            icon: const Icon(Icons.currency_exchange_outlined)),
        IconButton(
            onPressed: _model.loadReport,
            icon: const Icon(Icons.receipt_long_outlined)),
        AppNavPopupMenuButton(model: model),
      ],
    );
  }

  @override
  Widget body() {
    return BlocBuilder<AppBloc, AppState>(builder: (context, state) {
      if (state is AppStateShifts) {
        _model.handleState(state.data);
      }
      final l10n = model.locale();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_model.hasPrintPayload)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _model.printLastReport(model),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(l10n.printReport),
                ),
              ),
            ),
          Expanded(
            child: _model.printing.isEmpty
                ? const Center(child: Text('No report data'))
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: ListView.separated(
                      itemCount: _model.printing.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(
                          _model.printing[i],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class _CashMoveMoneyDialog extends StatefulWidget {
  final int sessionId;

  const _CashMoveMoneyDialog({required this.sessionId});

  @override
  State<_CashMoveMoneyDialog> createState() => _CashMoveMoneyDialogState();
}

class _CashMoveMoneyDialogState extends State<_CashMoveMoneyDialog> {
  final amountController = TextEditingController();
  final commentController = TextEditingController();
  bool isInput = false;

  @override
  void dispose() {
    amountController.dispose();
    commentController.dispose();
    super.dispose();
  }

  String _now() => DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  void _applyPresetComment() {
    commentController.text =
        '${_l10n.cashMoveMoneyPresetWithdraw} #${widget.sessionId} ${_now()}';
  }

  double _amount() {
    final s = amountController.text.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }

  Future<void> _pickAmountWithNumpad() async {
    final current = amountController.text.trim();
    final next = await showDialog<String>(
      context: context,
      builder: (_) => _NumPadDialog(initial: current),
    );
    if (next == null) return;
    amountController.text = next;
  }

  void _submit() {
    final amount = _amount();
    if (amount <= 0) {
      Dialogs.show(_l10n.cashMoveMoneyEnterAmount);
      return;
    }
    final comment = commentController.text.trim();
    Navigator.pop(
      context,
      <String, dynamic>{
        'f_order_id': 0,
        'f_payment_type_id': 1,
        'f_currency_id': 1,
        'f_debit': isInput ? amount : 0,
        'f_credit': isInput ? 0 : amount,
        'f_comment': comment,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return AlertDialog(
      title: Text(l10n.cashMoveMoneyTitle),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => isInput = true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isInput ? Colors.indigo : null,
                    ),
                    child: Text(
                      l10n.cashMoveMoneyInput,
                      style: TextStyle(
                        color: isInput ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => isInput = false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !isInput ? Colors.indigo : null,
                    ),
                    child: Text(
                      l10n.cashMoveMoneyOutput,
                      style: TextStyle(
                        color: !isInput ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              readOnly: true,
              onTap: _pickAmountWithNumpad,
              decoration: InputDecoration(
                labelText: l10n.cashMoveMoneyAmount,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilledButton.tonal(
                    onPressed: _applyPresetComment,
                    child: Text(
                        '${l10n.cashMoveMoneyPresetWithdraw} #${widget.sessionId} ${_now()}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            MTextFormField(
              controller: commentController,
              readOnly: true,
              hintText: l10n.cashMoveMoneyComment,
              onTap: () async {
                final v = await Kbd.getText();
                if (v != null) {
                  commentController.text = v;
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.cashMoveMoneySave),
        ),
      ],
    );
  }
}

class _NumPadDialog extends StatefulWidget {
  final String initial;

  const _NumPadDialog({required this.initial});

  @override
  State<_NumPadDialog> createState() => _NumPadDialogState();
}

class _NumPadDialogState extends State<_NumPadDialog> {
  late final TextEditingController _controller;
  static const _keys = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '.',
    '0',
    '⌫',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press(String k) {
    final t = _controller.text;
    if (k == '⌫') {
      if (t.isEmpty) return;
      _controller.text = t.substring(0, t.length - 1);
      return;
    }
    if (k == '.' && t.contains('.')) return;
    _controller.text = numpadMoneyKeyResult(t, k);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.cashMoveMoneyAmount),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              itemCount: _keys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.1,
              ),
              itemBuilder: (_, i) {
                final k = _keys[i];
                return OutlinedButton(
                  onPressed: () => setState(() => _press(k)),
                  child: Text(k, style: const TextStyle(fontSize: 18)),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.cashMoveMoneySave),
        ),
      ],
    );
  }
}
