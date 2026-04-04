import 'dart:async';
import 'dart:convert';

import 'package:carwash/l10n/app_localizations.dart';
import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/screens/history_pay_dialog.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:carwash/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'history.part.dart';

class HistoryScreen extends AppScreen {
  final _model = HistoryModel();

  HistoryScreen(super.model, {super.key});

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
              return Text(_model.sessionTitle);
            })),
        IconButton(
            onPressed: refreshReport,
            icon: const Icon(Icons.refresh_outlined)),
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
                    _model.loadReport();
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
                  if (_model.printing.isEmpty) {
                    return const Center(child: Text('No report data'));
                  }
                  return _reportList();
                }
                if (_model.goodsRows.isEmpty) {
                  return Center(child: Text(l10n.historyNoGoodsRows));
                }
                return _goodsTable(l10n);
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _reportList() {
    Widget cell(String text, double width, {bool bold = false}) {
      return SizedBox(
        width: width,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    Widget asRow(String row, {bool header = false}) {
      final parts = row.split('|').map((e) => e.trim()).toList();
      final c1 = parts.isNotEmpty ? parts[0] : '';
      final c2 = parts.length > 1 ? parts[1] : '';
      final c3 = parts.length > 2 ? parts[2] : '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            cell(c1, 190, bold: header),
            cell(c2, 240, bold: header),
            cell(c3, 140, bold: header),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 590,
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                asRow('Open date | Payment | Order', header: true),
                Expanded(
                  child: ListView.builder(
                    itemCount: _model.printing.length,
                    itemBuilder: (_, i) => asRow(_model.printing[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _goodsTable(AppLocalizations l10n) {
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
                DataColumn(label: Text(l10n.historyColCar)),
                DataColumn(label: Text(l10n.historyColService)),
                DataColumn(label: Text(l10n.historyColDaily)),
                DataColumn(label: Text(l10n.historyColStatus)),
                DataColumn(label: Text(l10n.historyPay)),
              ],
              rows: _model.goodsRows.map((r) {
                return DataRow(
                  cells: [
                    DataCell(Text(r.car)),
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(
                        r.service,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(r.daily)),
                    DataCell(Text(r.statusLabel)),
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.historyPay,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      onTap: () {
                        unawaited(openGoodsPayForHistory(this, r));
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
