import 'dart:async';

import 'package:carwash/screens/app/appbloc.dart';
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
    return BlocListener<AppBloc, AppState>(listener: (c, s){
      if (s is AppStateClosed) {
        model.navCashSession();
      }
    }, child: _body());

  }

  Widget _body() {
    return BlocBuilder<AppBloc, AppState>(builder: (context, state) {
      if (state is AppStateShifts) {
        _model.handleReportsState(model, state.data);
      }
      if (_model.printing.isEmpty) {
        return const Center(child: Text('No report data'));
      }
      return Container(
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
    });
  }
}
