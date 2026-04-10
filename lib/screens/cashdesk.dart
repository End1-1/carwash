import 'dart:async';

import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cashdesk.part.dart';

class CashdeskScreen extends AppScreen {
  static final _model = CashdeskModel();

  CashdeskScreen(super.model, {super.key}) {
    _model.onEnter();
  }

  /// Синхронизация смены с сервером и выбор [CashdeskModel.sessionId] из prefs
  /// (`cashsession`), чтобы отчёт сразу строился по активной смене.
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
      title: Text(prefs.appTitle()),
      actions: [
        IconButton(
            onPressed: _model.chooseSession,
            icon: const Icon(Icons.list_alt_outlined)),
        Container(
            alignment: Alignment.center,
            width: 120,
            child: BlocBuilder<AppBloc, AppState>(builder: (context, state) {
              final sid = _model.sessionId;
              if (sid <= 0) {
                return const Text('');
              }
              return Text('Session #$sid');
            })),
        IconButton(
            onPressed: _model.refreshReport,
            icon: const Icon(Icons.receipt_long_outlined)),
        IconButton(
            onPressed: () => _model.closeDay(model),
            icon: const Icon(Icons.edit_calendar_sharp)),
      ],
    );
  }

  @override
  Widget body() {
    return BlocListener<AppBloc, AppState>(
      listener: (c, s) {
        if (s is AppStateClosed) {
          model.navHome();
        }
      },
      child: _body(),
    );
  }

  Widget _body() {
    return BlocBuilder<AppBloc, AppState>(builder: (context, state) {
      if (state is AppStateShifts) {
        _model.handleReportsState(model, state.data);
      }
      final noSession = (prefs.getInt('cashsession') ?? 0) <= 0;
      final l10n = model.locale();
      Widget reportPane;
      if (_model.printing.isEmpty) {
        reportPane = Center(
          child: Text(noSession ? '' : 'No report data'),
        );
      } else {
        reportPane = Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            itemCount: _model.printing.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final row = _model.printing[i];
              return ListTile(
                dense: true,
                title: Text(row, style: const TextStyle(fontSize: 13)),
              );
            },
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (noSession)
            Material(
              color: Colors.orange.shade100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        model.cashboxIdForOrder <= 0
                            ? l10n.cashboxNotConfigured
                            : l10n.noActiveSession,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    if (model.cashboxIdForOrder > 0)
                      TextButton(
                        onPressed: model.navCashSession,
                        child: Text(l10n.startNewShift),
                      ),
                  ],
                ),
              ),
            ),
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
          Expanded(child: reportPane),
        ],
      );
    });
  }
}
