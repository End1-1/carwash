import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/app_nav_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cashsession.part.dart';

class CashSession extends AppScreen {
  const CashSession(super.model, {super.key});

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
        AppNavPopupMenuButton(model: model),
      ],
    );
  }

  @override
  Widget body() {
    return BlocListener<AppBloc, AppState>(
      listenWhen: (p, c) =>
          c is AppStateCashSession || c is AppStateError,
      listener: (context, state) {
        if (state is AppStateError) {
          model.dialogController.add(state.error.toString());
          return;
        }
        if (state is AppStateCashSession) {
          final raw = state.data;
          var sid = 0;
          final cbs = raw['cashbox_session'];
          if (cbs is Map) {
            sid = int.tryParse('${cbs['f_id']}') ?? 0;
          }
          if (sid <= 0) {
            final legacy = raw['cashsession'];
            if (legacy is Map) {
              sid = int.tryParse('${legacy['f_id']}') ?? 0;
            }
          }
          if (sid <= 0) {
            sid = int.tryParse('${raw['cashbox_session_id']}') ?? 0;
          }
          if (sid > 0) {
            prefs.setInt('cashsession', sid);
            model.navHome();
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (model.cashboxIdForOrder <= 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                model.locale().cashboxNotConfigured,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          Center(child: Text(model.locale().noActiveSession)),
          Center(
              child: InkWell(
                  onTap: startNewSession,
                  child: Column(children: [
                    Icon(Icons.access_alarm_outlined, size: 60),
                    Text(model.locale().startNewShift)
                  ])))
        ],
      ),
    );
  }

}