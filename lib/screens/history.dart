import 'dart:async';
import 'dart:convert';

import 'package:carwash/l10n/app_localizations.dart';
import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/screens/history_pay_dialog.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:carwash/widgets/app_nav_popup_menu.dart';
import 'package:carwash/widgets/loading.dart';
import 'package:carwash/utils/web_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'history.part.dart';

class HistoryScreen extends AppScreen {
  final HistoryModel _model;

  HistoryScreen(
    super.model, {
    super.key,
    HistoryViewMode initialMode = HistoryViewMode.report,
  }) : _model = HistoryModel(initialMode: initialMode);

  void reloadGoodsProcess() => _model.loadGoodsProcess();

  @override
  PreferredSizeWidget appBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.home_outlined),
        onPressed: model.navHome,
      ),
      backgroundColor: Colors.green,
      toolbarHeight: kToolbarHeight,
      title: Text(prefs.appTitle()),
      actions: [
        Expanded(child: Container()),
        ValueListenableBuilder<HistoryViewMode>(
          valueListenable: _model.viewMode,
          builder: (context, mode, _) {
            return IconButton(
              onPressed: mode == HistoryViewMode.report ? chooseSession : null,
              icon: Icon(
                Icons.list_alt_outlined,
                color: mode == HistoryViewMode.report ? null : Colors.white38,
              ),
            );
          },
        ),
        Container(
            alignment: Alignment.center,
            width: 420,
            child: BlocBuilder<AppBloc, AppState>(builder: (context, state) {
              if (state is AppStateLoading) {
                return const Icon(Icons.timelapse);
              }
              return ValueListenableBuilder<String>(
                valueListenable: _model.sessionTitleListenable,
                builder: (context, title, _) {
                  return Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  );
                },
              );
            })),
        IconButton(
            onPressed: refreshReport, icon: const Icon(Icons.refresh_outlined)),
        AppNavPopupMenuButton(model: model),
        Expanded(child: Container())
      ],
    );
  }

  @override
  Widget body() {
    return ValueListenableBuilder<HistoryViewMode>(
      valueListenable: _model.viewMode,
      builder: (context, vm, _) {
        final l10n = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SegmentedButton<HistoryViewMode>(
                segments: [
                  ButtonSegment(
                    value: HistoryViewMode.report,
                    label: Text(l10n.historyModeReport),
                  ),
                  ButtonSegment(
                    value: HistoryViewMode.goodsDoneParking,
                    label: Text(l10n.historyModeDoneParking),
                  ),
                ],
                selected: {vm},
                onSelectionChanged: (Set<HistoryViewMode> s) {
                  final m = s.first;
                  if (_model.viewMode.value == m) return;
                  _model.viewMode.value = m;
                  if (m == HistoryViewMode.report) {
                    _model.goodsCarSearchController.clear();
                    if (_model.sessionId <= 0) {
                      _model.loadLastSessions();
                    } else {
                      _model.loadReport();
                    }
                  } else {
                    _model.loadGoodsProcess();
                  }
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<AppBloc, AppState>(builder: (context, state) {
                if (state is AppStateGoodsProcess) {
                  handleGoodsProcessState(state.data);
                }
                if (state is AppStateShifts) {
                  handleReportsState(state.data);
                }
                if (vm == HistoryViewMode.report) {
                  if (_model.reportRowsRaw.isEmpty) {
                    return Center(child: Text(l10n.historyNoReportData));
                  }
                  return ValueListenableBuilder<HistoryGoodsPaymentFilter>(
                    valueListenable: _model.reportPaymentFilter,
                    builder: (context, filt, _) {
                      final rows = _filteredReportRows(filt);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _historyPaymentFilterBar(
                            l10n,
                            filt,
                            _model.reportPaymentFilter,
                          ),
                          Expanded(
                            child: rows.isEmpty
                                ? Center(
                                    child: Text(l10n.historyGoodsFilterNoRows))
                                : _reportList(l10n, rows),
                          ),
                          if (rows.isNotEmpty) _reportTotalBar(l10n, rows),
                        ],
                      );
                    },
                  );
                }
                if (_model.goodsRows.isEmpty) {
                  return Center(child: Text(l10n.historyNoGoodsRows));
                }
                return ValueListenableBuilder<HistoryGoodsPaymentFilter>(
                  valueListenable: _model.goodsPaymentFilter,
                  builder: (context, filt, _) {
                    final afterPay = _applyGoodsPaymentFilter(filt);
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _model.goodsCarSearchController,
                      builder: (context, tv, _) {
                        final rows = _applyGoodsCarSearch(afterPay, tv.text);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _historyPaymentFilterBar(
                              l10n,
                              filt,
                              _model.goodsPaymentFilter,
                            ),
                            _goodsCarSearchField(l10n),
                            Expanded(
                              child: rows.isEmpty
                                  ? Center(
                                      child: Text(
                                        afterPay.isEmpty
                                            ? l10n.historyGoodsFilterNoRows
                                            : l10n.historyGoodsCarSearchNoMatch,
                                      ),
                                    )
                                  : _goodsTable(l10n, rows),
                            ),
                            if (rows.isNotEmpty) _goodsTotalBar(l10n, rows),
                          ],
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        );
      },
    );
  }

  String _historyFmtMoney(double v) {
    if (v <= 0.009) return '—';
    if (v == v.roundToDouble()) return '${v.round()}';
    return v.toStringAsFixed(2);
  }

  List<HistoryGoodsRow> _applyGoodsPaymentFilter(
    HistoryGoodsPaymentFilter f,
  ) {
    switch (f) {
      case HistoryGoodsPaymentFilter.all:
        return List<HistoryGoodsRow>.from(_model.goodsRows);
      case HistoryGoodsPaymentFilter.unpaid:
        return _model.goodsRows.where((r) => r.canPay).toList();
      case HistoryGoodsPaymentFilter.cash:
        return _model.goodsRows.where((r) => r.paidCash > 0.009).toList();
      case HistoryGoodsPaymentFilter.card:
        return _model.goodsRows.where((r) => r.paidCard > 0.009).toList();
      case HistoryGoodsPaymentFilter.idram:
        return _model.goodsRows.where((r) => r.paidIdram > 0.009).toList();
    }
  }

  List<HistoryGoodsRow> _applyGoodsCarSearch(
    List<HistoryGoodsRow> rows,
    String query,
  ) {
    final needle = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (needle.isEmpty) return rows;
    return rows.where((r) {
      final car = r.car.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      return car.contains(needle);
    }).toList();
  }

  Widget _goodsCarSearchField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: TextField(
        controller: _model.goodsCarSearchController,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: l10n.historyGoodsSearchCarHint,
          prefixIcon: const Icon(Icons.search, size: 22),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  String _goodsPaymentFilterLabel(
    AppLocalizations l10n,
    HistoryGoodsPaymentFilter f,
  ) {
    switch (f) {
      case HistoryGoodsPaymentFilter.all:
        return l10n.historyGoodsFilterAll;
      case HistoryGoodsPaymentFilter.unpaid:
        return l10n.historyGoodsFilterUnpaid;
      case HistoryGoodsPaymentFilter.cash:
        return l10n.cash;
      case HistoryGoodsPaymentFilter.card:
        return l10n.card;
      case HistoryGoodsPaymentFilter.idram:
        return l10n.idram;
    }
  }

  Widget _historyPaymentFilterBar(
    AppLocalizations l10n,
    HistoryGoodsPaymentFilter selected,
    ValueNotifier<HistoryGoodsPaymentFilter> notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final f in HistoryGoodsPaymentFilter.values)
              FilterChip(
                label: Text(_goodsPaymentFilterLabel(l10n, f)),
                selected: selected == f,
                showCheckmark: false,
                onSelected: (_) {
                  notifier.value = f;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _reportList(
    AppLocalizations l10n,
    List<List<dynamic>> rawRows,
  ) {
    TextStyle cellStyle(BuildContext context, {bool bold = false}) {
      final onSurface = Theme.of(context).colorScheme.onSurface;
      final base = Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: onSurface,
              ) ??
          TextStyle(fontSize: 14, color: onSurface);
      return base.copyWith(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      );
    }

    Widget cellText(
      BuildContext context,
      String text, {
      bool bold = false,
      TextAlign align = TextAlign.start,
    }) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: cellStyle(context, bold: bold),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              horizontalMargin: 10,
              columnSpacing: 12,
              columns: [
                DataColumn(
                  label: Text(
                    l10n.historyColRow,
                    style: cellStyle(context, bold: true),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    l10n.historyReportColOpened,
                    style: cellStyle(context, bold: true),
                  ),
                ),
                DataColumn(
                  label: Text(
                    l10n.historyColCar,
                    style: cellStyle(context, bold: true),
                  ),
                ),
                DataColumn(
                  label: Text(
                    l10n.historyColAmount,
                    style: cellStyle(context, bold: true),
                  ),
                ),
                DataColumn(
                  label: Text(
                    l10n.order,
                    style: cellStyle(context, bold: true),
                  ),
                ),
              ],
              rows: [
                for (var i = 0; i < rawRows.length; i++)
                  DataRow(
                    cells: () {
                      final parts = _compactHistoryRow(rawRows[i])
                          .split('|')
                          .map((e) => e.trim())
                          .toList();
                      final c1 = parts.isNotEmpty ? parts[0] : '';
                      final c2 = parts.length > 1 ? parts[1] : '';
                      final c3 = parts.length > 2 ? parts[2] : '';
                      final c4 = parts.length > 3 ? parts[3] : '';
                      return [
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${i + 1}',
                              style: cellStyle(context),
                            ),
                          ),
                        ),
                        DataCell(cellText(context, c1)),
                        DataCell(cellText(context, c2)),
                        DataCell(cellText(context, c3)),
                        DataCell(cellText(context, c4)),
                      ];
                    }(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reportTotalBar(
    AppLocalizations l10n,
    List<List<dynamic>> rawRows,
  ) {
    final sum = _sumReportRowsTotal(rawRows);
    final count = rawRows.length;
    return Material(
      elevation: 6,
      color: Colors.green.shade800,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Text(
              '${l10n.historyGoodsTotal}:',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.historyReportOrdersCount(count),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (sum <= 0.009)
              Text(
                _historyFmtMoney(sum),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _historyFmtMoney(sum),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '֏',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _goodsTotalBar(
    AppLocalizations l10n,
    List<HistoryGoodsRow> rows,
  ) {
    final sum = rows.fold<double>(
      0,
      (a, r) => a + r.amountValue,
    );
    final waitingCount = rows.where((r) => r.isWaitingQueue).length;
    return Material(
      elevation: 6,
      color: Colors.green.shade800,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Text(
              '${l10n.historyGoodsTotal}:',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.historyWaitingCars(waitingCount),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.historyRowsInTable(rows.length),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (sum <= 0.009)
              Text(
                _historyFmtMoney(sum),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _historyFmtMoney(sum),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '֏',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _goodsTable(
    AppLocalizations l10n,
    List<HistoryGoodsRow> rows,
  ) {
    return Builder(
      builder: (context) {
        final primary = Theme.of(context).colorScheme.primary;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowHeight: 42,
              dataRowMinHeight: 44,
              columns: [
                DataColumn(
                  label: Text(l10n.historyColRow),
                  numeric: true,
                ),
                DataColumn(label: Text(l10n.historyColCar)),
                DataColumn(label: Text(l10n.historyColService)),
                DataColumn(label: Text(l10n.historyColDaily)),
                DataColumn(label: Text(l10n.historyColStatus)),
                DataColumn(
                  label: Text(l10n.historyColAmount),
                  numeric: true,
                ),
                DataColumn(label: Text(l10n.historyPay)),
                DataColumn(label: Text(l10n.cancel)),
              ],
              rows: List<DataRow>.generate(rows.length, (i) {
                final r = rows[i];
                return DataRow(
                  cells: [
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    DataCell(Text(r.car)),
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        r.service,
                        maxLines: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(r.daily)),
                    DataCell(Text(r.statusLabel)),
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          r.amountLabel,
                          style: TextStyle(
                            fontWeight:
                                r.canPay ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          r.canPay ? l10n.historyPay : r.paymentLabel,
                          style: TextStyle(
                            color: r.canPay ? primary : Colors.black54,
                            fontWeight: FontWeight.w600,
                            decoration: r.canPay
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      onTap: r.canPay
                          ? () => unawaited(openGoodsPayForHistory(this, r))
                          : null,
                    ),
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      onTap: () => unawaited(cancelOrderForHistory(this, r)),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
