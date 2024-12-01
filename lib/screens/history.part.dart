part of 'history.dart';

class HistoryModel {
  var shiftName = '';
  var shiftId = 0;

  HistoryModel() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryShift(
        '/engine/carwash/shift.php', <String, dynamic>{'action': 'getshifts'}));
  }
}

extension HistoryE on HistoryScreen {
  void goBack() {
    if (_model.shiftId == 0) {
      return;
    }

    go(_model.shiftId - 1);
  }

  void goForward() {
    if (_model.shiftId == 0) {
      return;
    }
    go(_model.shiftId + 1);
  }

  void go(int shift) {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryShift(
        '/engine/carwash/shift.php',
        <String, dynamic>{'action': 'getshifts', 'shift': shift}));
  }

  void printFiscal(dynamic d) {
    if (d['f_fiscal'] > 0) {
      return;
    }
    BlocProvider.of<QuestionBloc>(prefs.context()).add(QuestionEventRaise(
        '${model.tr('Print fiscal')}\r\n ${d['f_amounttotal']} ${nameOfPayment(d)}',
        () {

          final jsonMsg = <String,dynamic>{};
          jsonMsg['command'] = 'fiscal';
          jsonMsg['handler'] = 'fiscal';
          jsonMsg['key'] = "asdf7fa8kk49888d!!jjdjmskkak98983mj???m";
          jsonMsg['order'] =  d['f_id'];
          model.dialogController.add(1);
          model.appWebsocket.sendMessage(jsonEncode(jsonMsg), (json) { model.printFiscalResponse(json);go(_model.shiftId);});

    }, () {}));
  }

  void printBill(dynamic d) {

    BlocProvider.of<QuestionBloc>(prefs.context()).add(QuestionEventRaise(
        model.tr('Reprint bill'),
            () {

              final jsonMsg = <String,dynamic>{};
              jsonMsg['command'] = 'fiscal';
              jsonMsg['handler'] = 'printbill';
              jsonMsg['key'] = "asdf7fa8kk49888d!!jjdjmskkak98983mj???m";
              jsonMsg['order'] =  d['f_id'];
              model.dialogController.add(2);
              model.appWebsocket.sendMessage(jsonEncode(jsonMsg), (json) { model.printBillResponse(json);go(_model.shiftId);});

          // model.httpQuery2(
          //     AppModel.query_print_bill, {'id': d['f_id'], 'mode': 1, 'debug_res': Prefs.debug_res},
          //     route: HttpQuery2.printbill, callback: () {
          //   go(_model.shiftId);
          //});
        }, () {}));
  }

  void changePayment(dynamic d) {
    final variants = <String>[];
    if (d['f_amountcash'] == 0) {
      variants.add(model.tr('Cash'));
    }
    if (d['f_amountcard'] == 0) {
      variants.add(model.tr('Card'));
    }
    if (d['f_amountidram'] == 0) {
      variants.add(model.tr('Idram'));
    }
    BlocProvider.of<QuestionBloc>(prefs.context())
        .add(QuestionEventList(variants, (v) {
      if (v < 0) {
        return;
      }
      final up = <String, dynamic>{
        'action': 'changePayment',
        'shift': _model.shiftId,
        'f_amountcash': 0,
        'f_amountcard': 0,
        'f_amountidram': 0,
        'f_id': d['f_id']
      };
      if (variants[v] == model.tr('Cash')) {
        up['f_amountcash'] = d['f_amounttotal'];
      } else if (variants[v] == model.tr('Card')) {
        up['f_amountcard'] = d['f_amounttotal'];
      } else if (variants[v] == model.tr('Idram')) {
        up['f_amountidram'] = d['f_amounttotal'];
      }
      BlocProvider.of<AppBloc>(prefs.context())
          .add(AppEventChangePayment('/engine/carwash/shift.php', up));
    }));
  }

  String nameOfPayment(dynamic d) {
    if ((d['f_amountcard'] ?? 0) > 0) {
      return model.tr('Card');
    }
    if ((d['f_amountidram'] ?? 0) > 0) {
      return model.tr('Idram');
    }
    return model.tr('Cash');
  }
}
