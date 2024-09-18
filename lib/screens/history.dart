import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/http_query.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'history.part.dart';

class HistoryScreen extends AppScreen {
  final _model = HistoryModel();

  HistoryScreen(super.model, {super.key});

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
        IconButton(onPressed: goBack, icon: const Icon(Icons.arrow_circle_left_outlined)),
        Container(alignment: Alignment.center, width: 300, child: BlocBuilder<AppBloc, AppState>(builder: (context, state) {
          if (state  is AppStateLoading) {
            return const Icon(Icons.timelapse);
          }
          if (state is AppStateShifts) {
            _model.shiftId  = state.data['data']['f_id'];
            _model.shiftName = state.data['data']['f_open'];
          }
          return Text('${_model.shiftId}, ${_model.shiftName}');
        })),
        IconButton(onPressed: goForward, icon: const Icon(Icons.arrow_circle_right_outlined)),
        Expanded(child: Container())
      ],
    );
  }

  @override
  Widget body() {
    return BlocBuilder<AppBloc,AppState>(builder:(context, state){
      if (state is AppStateLoading) {

      }
      if (state is AppStateShifts) {
        return SingleChildScrollView(
          child: Column(
            children: [
              for (final e in state.data['orders'] ?? [])...[
                _oneRow(e),
                Divider(),
              ]
            ],
          ),
        );
      }
      return Text('?');
    });
  }

  Widget _oneRow(dynamic d) {
    const ts = const TextStyle(fontSize: 20);
    return Row(
      children: [
      SizedBox(width: 100, child: Text(d['f_govnumber'], style: ts)),
      SizedBox(width: 100, child: Text(d['f_hallid'], style: ts)),
      SizedBox(width: 100, child: Text(d['f_timeclose'], style: ts)),
      SizedBox(width: 100, child: Text('${d['f_amounttotal']}', style: ts)),
      InkWell(onTap:(){
        changePayment(d);
      }, child:SizedBox(width: 100, child: Text(nameOfPayment(d), style: ts))),
      InkWell(onTap:(){
        printFiscal(d);
      }, child:SizedBox(width: 100, height: 30, child: Image.asset(d['f_fiscal'] > 0 ? 'assets/icons/basketball.png' : 'assets/icons/football.png'))),
      ],
    );
  }

}