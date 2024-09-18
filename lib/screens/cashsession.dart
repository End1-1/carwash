import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
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
        IconButton(
            onPressed: model.navBasket,
            icon: SizedBox(
                width: 24,
                height: 24,
                child: Stack(alignment: Alignment.center, children: [
                  const Icon(Icons.shopping_basket_outlined),
                  StreamBuilder(
                      stream: model.basketController.stream,
                      builder: (builder, snapshot) {
                        if (model.appdata.basket.isEmpty) {
                          return Container();
                        }
                        return Align(
                            alignment: Alignment.topRight,
                            child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text('${model.appdata.basket.length}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold))));
                      })
                ])))
      ],
    );
  }

  @override
  Widget body() {
    return BlocListener<AppBloc, AppState>(
      listenWhen: (p, c) => c is AppStateCashSession,
        listener: (context, state) {
        if (state is AppStateCashSession) {
          prefs.setInt('cashsession', state.data['cashsession']['f_id']);
          if ((prefs.getInt('cashsession') ?? 0) > 0) {
            model.navHome();
          }
        }

    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(child: Text(model.tr('No active session'))),
        Center(child: InkWell(onTap: startNewSession, child: Column(children: [
          Icon(Icons.access_alarm_outlined, size: 60),
          Text(model.tr('Start new shift'))
        ])))
      ],
    ));
  }

}