import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/utils/styles.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cashdesk.part.dart';

class CashdeskScreen extends AppScreen {
  static final _model = CashdeskModel();

  CashdeskScreen(super.model, {super.key}) {
    _model.refresh();
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
            onPressed: _model.newRow,
            icon: Icon(Icons.add_circle_outline_outlined)),
        IconButton(
            onPressed: _model.refresh, icon: Icon(Icons.refresh_outlined)),
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
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
              child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      BlocBuilder<CashBloc, CashState>(builder: (builder, state) {
                        if (state is CashStateDeals) {
                          var i = 1;
                          return Column(children: [
                            for (final d in state.deals) ...[
                              Row(
                                children: [
                                  Text('${i++}.'),
                                  Styling.rowSpacingWidget(),
                                  if (d['id'].isEmpty)
                                    Expanded(
                                        child: Styling.textFormField(
                                            _model.textController,
                                            'Նպատակ'))
                                  else
                                    Expanded(child: Styling.text(d['purpose'])),
                                  Styling.rowSpacingWidget(),
                                  IconButton(
                                      onPressed: _model.setPurpose,
                                      icon: Icon(Icons.menu_open_rounded)),
                                  Styling.rowSpacingWidget(),
                                  SizedBox(
                                      width: 100,
                                      child: d['id'].isEmpty
                                          ? Styling.textFormFieldNumbers(
                                          _model.amountController,
                                          'Գումար')
                                          : Styling.text('${d['amount']}')),
                                  Styling.rowSpacingWidget(),
                                  if (d['id'].isEmpty)
                                    IconButton(
                                        onPressed: _model.save,
                                        icon: Icon(Icons.save_outlined))
                                  else
                                    IconButton(
                                        onPressed: () {
                                          _model.removeOut(d);
                                        },
                                        icon: const Icon(
                                            Icons.remove_circle_outline_outlined))
                                ],
                              ),
                              const Divider(),
                            ]
                          ]);
                        }
                        return Container();
                      }),
                      BlocBuilder<AppBloc, AppState>(
                          buildWhen: (p, c) => c is AppStateCash,
                          builder: (builder, state) {
                            if (state is AppStateCash) {
                              return Column(children: [
                                Styling.textColor('Մուտքեր', 30, true, Colors.green),
                                for (final e in state.data['totalin']) ...[
                                  Row(children: [
                                    Styling.textColor(
                                        e['f_name'], 14, true, Colors.green),
                                    Styling.rowSpacingWidget(),
                                    Styling.textColor(
                                        '${e['f_amount']}', 14, true, Colors.green),
                                  ]),
                                  Styling.columnSpacingWidget(),
                                  const Divider()
                                ],
                                Styling.textColor('Ելքեր', 30, true, Colors.redAccent),
                                for (final e in state.data['totalout']) ...[
                                  Row(children: [
                                    Styling.textColor(
                                        e['f_remarks'], 14, true, Colors.redAccent),
                                    Styling.rowSpacingWidget(),
                                    Styling.textColor(
                                        e['f_amount'], 14, true, Colors.redAccent),
                                    Expanded(child: Container()),
                                    IconButton(
                                        onPressed: () {
                                          _model.removeOut(e);
                                        },
                                        icon: Icon(Icons.highlight_remove_sharp))
                                  ]),
                                  Styling.columnSpacingWidget(),
                                  const Divider()
                                ]
                              ]);
                            }
                            return Container();
                          })
                    ],
                  ))),
          Container(
              padding: const EdgeInsets.all(10),
              child: BlocBuilder<AppBloc, AppState>(
                  buildWhen: (p, c) => c is AppStateCash,
                  builder: (builder, state) {
                    if (state is AppStateCash) {
                      return Row(children:[
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:[
                              Styling.textColor(
                                  'Ընդամենը ${_model.total(state.data['total'])}', 30, true, Colors.blue),
                              Styling.textColor(
                                  'Կանխիկ ${state.data['total'].firstWhere((e) => e['f_name'] == 'Կանխիկ', orElse:()=>{'f_amount':'0'})['f_amount']}', 30, true, Colors.green),
                              Styling.textColor(
                                  'Քարտ ${state.data['total'].firstWhere((e) => e['f_name'] == 'Անկանխիկ', orElse:()=>{'f_amount':'0'})['f_amount']}', 30, true, Colors.blueGrey),
                              Styling.textColor(
                                  'Idram ${state.data['total'].firstWhere((e) => e['f_name'] == 'Idram', orElse:()=>{'f_amount':'0'})['f_amount']}', 30, true, Colors.blue),]),
                        Expanded(child: Container()),
                        IconButton(onPressed: _model.closeDay, icon: const Icon(Icons.edit_calendar_sharp, size: 40,))
                      ]);
                    }
                    return Container();
                  }))
        ]);
  }
}
