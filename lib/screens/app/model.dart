import 'dart:async';
import 'dart:convert';

import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/basket.dart';
import 'package:carwash/screens/car_number.dart';
import 'package:carwash/screens/cashdesk.dart';
import 'package:carwash/screens/cashsession.dart';
import 'package:carwash/screens/dishes.dart';
import 'package:carwash/screens/help/screen_help.dart';
import 'package:carwash/screens/history.dart';
import 'package:carwash/screens/login.dart';
import 'package:carwash/screens/process.dart';
import 'package:carwash/screens/process_end.dart';
import 'package:carwash/screens/settings.dart';
import 'package:carwash/screens/welcome.dart';
import 'package:carwash/screens/widgets/states.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/http_query.dart';
import 'package:carwash/utils/logging.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/utils/web_query.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:carwash/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../status.dart';
import 'data.dart';

class AppModel {
  static const query_call_function = -1;
  static const query_init = 1;
  static const query_create_order = 2;
  static const query_get_process_list = 3;
  static const query_end_order = 4;
  static const query_start_order = 5;
  static const query_update_duration = 6;
  static const query_reassign_table = 7;
  static const query_payment = 8;
  static const query_print_bill = 9;
  static const query_print_fiscal = 10;

  final titleController = TextEditingController();
  final settingsServerAddressController = TextEditingController();
  final settingsWebServerAddressController = TextEditingController();
  final configController = TextEditingController();
  final menuCodeController = TextEditingController();
  final modeController = TextEditingController();
  final carNumberController = TextEditingController();
  final showUnpaidController = TextEditingController();
  final tableController = TextEditingController();
  final afterBasketToOrdersController = TextEditingController();
  final messageController = TextEditingController();

  final basketController = StreamController.broadcast();
  final dishesController = StreamController.broadcast();
  final dialogController = StreamController();
  final fiscalController = StreamController.broadcast();

  late final Data appdata;

  Size? screenSize;
  var screenMultiple = 0.43;
  var printFiscal = true;
  var login = false;

  AppModel() {
    appdata = Data(this);
    dialogController.stream.listen((event) {
      if (event is int) {
        Loading.show();
      } else if (event is String) {
        if (event.isEmpty) {
          return;
        }
        Dialogs.show(event);
      }
    });
  }

  void configScreenSize() {
    if (screenSize!.width > 500) {
      screenMultiple = 0.3;
    } else if (screenSize!.width >= 1240) {
      screenMultiple = 0.2;
    }
  }

  Future<String> initModel() async {
    // dialogController.add(1);
    final loginResult = await WebHttpQuery('/engine/login.php')
        .request({'method': 3, 'sessionkey': prefs.string('passhash')});
    if (loginResult['status'] == 1) {
      login = true;
      prefs.setInt('user_group', loginResult['data']['user']['f_group']);
      prefs.setInt('cashsession', loginResult['data']['cashsession']['f_id']);
    }

    final queryResult = await WebHttpQuery('/engine/carwash/init-data.php')
        .request({'f_menu': int.tryParse(prefs.string('menucode')) ?? 0});
    //Navigator.pop(Loading.dialogContext);

    if (queryResult['status'] == 1) {
      String s = queryResult['data'][0];
      httpOk(query_init, jsonDecode(s));
      return '';
    } else {
      dialogController.add(queryResult['data']);
      return queryResult['data'];
    }
  }

  String tr(String key) {
    if (!appdata.translation.containsKey(key)) {
      appdata.translation[key] = {'f_en': key, 'f_am': key, 'f_ru': key};
      WebHttpQuery('/engine/carwash/unknown-tr.php').request({'f_en': key});
    }
    if (appdata.translation[key]!['f_am'].isEmpty) {
      return key;
    }
    return appdata.translation[key]!['f_am']!;
  }

  Future<void> tryLogin(String? pin) async {
    final result = await WebHttpQuery('/engine/login.php')
        .request({'method': 2, 'pin': pin ?? ''});
    if (result['status'] == 1) {
      login = true;
      prefs.setString('passhash', result['data']['sessionkey']);
      prefs.setInt('user_group', result['data']['user']['f_group']);
      prefs.setInt('cashsession', result['data']['cashsession']['f_id']);
      if ((prefs.getInt('cashsession') ?? 0) > 0) {
        navHome();
      } else {
        navCashSession();
      }
    } else {
      dialogController.add(result['data']);
    }
  }

  void openMenu() {
    BlocProvider.of<AppAnimateBloc>(prefs.context())
        .add(AppAnimateEventRaise());
  }

  void navLogin() {
    Navigator.pushAndRemoveUntil(
        prefs.context(),
        MaterialPageRoute(builder: (builder) => LoginScreen(this)),
        (route) => false);
  }

  void navHome() {
    if (login) {
      Navigator.pushAndRemoveUntil(
          Prefs.navigatorKey.currentContext!,
          MaterialPageRoute(builder: (builder) => WelcomeScreen(this)),
          (r) => false);
    } else {
      navLogin();
    }
  }

  void navCashSession() {
    Navigator.pushAndRemoveUntil(
        Prefs.navigatorKey.currentContext!,
        MaterialPageRoute(builder: (builder) => CashSession(this)),
        (r) => false);
  }

  void navHelp() {
    Navigator.pushAndRemoveUntil(
        Prefs.navigatorKey.currentContext!,
        MaterialPageRoute(builder: (builder) => ScreenHelp(this)),
        (r) => false);
  }

  void navSettings() {
    Dialogs.getPin().then((value) {
      if ((value ?? '') == '1981') {
        settingsServerAddressController.text = prefs.string('serveraddress');
        settingsWebServerAddressController.text =
            prefs.string('webserveraddress');
        menuCodeController.text = prefs.string('menucode');
        modeController.text = prefs.string('appmode');
        showUnpaidController.text = prefs.string('showunpaid');
        tableController.text = prefs.string('table');
        configController.text = prefs.string('config');
        titleController.text = prefs.string('title');
        afterBasketToOrdersController.text =
            prefs.string('afterbaskettoorders');
        Navigator.push(Prefs.navigatorKey.currentContext!,
            MaterialPageRoute(builder: (builder) => SettingsScreen(this)));
      }
    });
  }

  void navProcess() {
    Navigator.push(Prefs.navigatorKey.currentContext!,
        MaterialPageRoute(builder: (builder) => ProcessScreen(this)));
  }

  void navCashdesk() {
    Navigator.push(Prefs.navigatorKey.currentContext!,
        MaterialPageRoute(builder: (builder) => CashdeskScreen(this)));
  }

  void navHistory() {
    Navigator.push(Prefs.navigatorKey.currentContext!,
        MaterialPageRoute(builder: (builder) => HistoryScreen(this)));
  }

  void navStatus() {
    Navigator.pop(prefs.context());
    Navigator.push(prefs.context(),
        MaterialPageRoute(builder: (builder) => StatusScreen(this)));
  }

  void saveSettings() {
    prefs.setString('serveraddress', settingsServerAddressController.text);
    prefs.setString(
        'webserveraddress', settingsWebServerAddressController.text);
    prefs.setString('menucode', menuCodeController.text);
    prefs.setString('appmode', modeController.text);
    prefs.setString('showunpaid', showUnpaidController.text);
    prefs.setString('table', tableController.text);
    prefs.setString('title', titleController.text);
    prefs.setString('config', configController.text);
    prefs.setString('afterbaskettoorders', afterBasketToOrdersController.text);
    initModel().then((value) {
      if (login) {
        navHome();
      } else {
        navLogin();
      }
    });
  }

  void closeQuestionDialog() {
    BlocProvider.of<QuestionBloc>(prefs.context()).add(QuestionEvent());
  }

  void navDishes(filter) {
    Navigator.push(Prefs.navigatorKey.currentContext!,
        MaterialPageRoute(builder: (builder) => DishesScreen(this, filter)));
  }

  void navBasketFromNumber() {
    if (carNumberController.text.length < 5) {
      Dialogs.show(tr('Car number incorrect'));
      return;
    }
    Navigator.push(Prefs.navigatorKey.currentContext!,
        MaterialPageRoute(builder: (builder) => BasketScreen(this)));
  }

  void navBasket() {
    if (prefs.string('appmode') == '1') {
      if (appdata.basket.isEmpty) {
        Dialogs.show(tr('Your basket is empty'));
        return;
      }
      Navigator.push(Prefs.navigatorKey.currentContext!,
          MaterialPageRoute(builder: (builder) => CarNumberScreen(this)));
      return;
    }
    Navigator.push(Prefs.navigatorKey.currentContext!,
        MaterialPageRoute(builder: (builder) => BasketScreen(this)));
  }

  void closeErrorDialog() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEvent());
  }

  Future<void> removeOrder(Map<String, dynamic> data) async {
    WebHttpQuery('/engine/carwash/remove-order.php')
        .request(data)
        .then((value) {
      getProcessList();
    });
  }

  Future<void> changeStateOfProcess(Map<String, dynamic> data) async {
    WebHttpQuery('/engine/carwash/status.php').request(data).then((value) {
      getProcessList();
    });
  }

  void callStaff() {
    navHelp();
  }

  void addToBasket(Map<String, dynamic> data) {
    data['f_uuid'] = const Uuid().v1().toString();
    appdata.basket.add(data);
    appdata.basketTotal();
    basketController.add(appdata.basket.length);
  }

  void processOrder() {
    if (carNumberController.text.isEmpty) {
      Dialogs.show('Նշեք մեքենայի պետհամարանիշը');
      return;
    }
    List<Map<String, dynamic>> m = [];
    for (var e in appdata.basket) {
      final a = <String, dynamic>{};
      a.addAll(e);
      a.remove('f_image');
      m.add(a);
    }
    httpQuery(
        query_create_order,
        {
          'order': appdata.basketData,
          'items': m,
          'f_staff': 1,
          'f_amountcash':appdata.basketData['f_amountcash'],
          'f_amountcard':appdata.basketData['f_amountcard'],
          'f_amountidram':appdata.basketData['f_amountidram'],
          'cashsession': prefs.getInt('cashsession') ?? 0,
          'f_table': int.tryParse(prefs.string('table')) ?? 1,
          'car_number': carNumberController.text
        },
        '/engine/carwash/create-order.php');
  }

  void getProcessList() async {
    basketController.add(null);
    final queryResult =
        await WebHttpQuery('/engine/carwash/get-process-list.php')
            .request({'f_menu': int.tryParse(prefs.string('menucode')) ?? 0});
    if (queryResult['status'] == 1) {
      httpOk(
          query_get_process_list, jsonDecode(queryResult['data'][0])['data']);
    } else {}
  }

  void startOrder(Map<String, dynamic> o) {
    httpQuery(query_start_order, o, '/engine/carwash/start-order.php');
  }

  void changeState(Map<String, dynamic> o) async {
    ProcessStates.show(o, this).then((value) {});
  }

  void endOrder(Map<String, dynamic> o) {
    ProcessEndScreen.show(o, this).then((value) {
      if (value ?? false) {
        getProcessList();
      }
    });
  }

  void httpOk(int code, dynamic data) {
    switch (code) {
      case query_init:
        appdata.part1.clear();
        appdata.part2.clear();
        appdata.dish.clear();
        appdata.tables.clear();
        appdata.translation.clear();
        for (final e in data['part1'] ?? []) {
          if (appdata.part1filter == 0) {
            appdata.part1filter = e['f_id'];
          }
          appdata.part1.add(e);
        }
        for (final e in data['part2'] ?? []) {
          appdata.part2.add(e);
        }
        for (final e in data['dish'] ?? []) {
          appdata.dish.add(e);
        }
        for (final e in data['tables'] ?? []) {
          appdata.tables.add(e);
        }
        for (final e in data['translator'] ?? []) {
          appdata.translation[e['f_en']] = e;
        }
        break;
      case query_print_fiscal:
        appdata.basket.clear();
        appdata.basketData.clear();
        carNumberController.clear();
        appdata.basketTotal();
        Dialogs.show(tr('Your order was created')).then((value) {
          if (prefs.string('afterbaskettoorders') == '1') {
            navProcess();
          } else {
            navHome();
          }
        });
        break;
      case query_create_order:
        Logging.write('Order created');
        appdata.basketData['f_id'] = data['data'];
        if ((appdata.basketData['f_amountcash'] ?? 0) > 0 ||
            (appdata.basketData['f_amountcard'] ?? 0) > 0 ||
            (appdata.basketData['f_amountidram'] ?? 0) > 0) {
          if (prefs.string('serveraddress') != '-1') {
            Map<String,dynamic> dd = {};
            if (data is String) {
              dd.addAll(jsonDecode(data));
            } else {
              dd.addAll(data);
            }
            Logging.write('Order created, print fiscal $data route: ${HttpQuery2.printfiscal}');
            httpQuery2(query_print_fiscal,
                {'id': dd["data"],
                  'mode': printFiscal ? 1 : 0},
                route: HttpQuery2.printfiscal);
          } else {
            Logging.write('Order created, no fiscal');
            appdata.basket.clear();
            appdata.basketData.clear();
            carNumberController.clear();
            appdata.basketTotal();
            Dialogs.show(tr('Your order was created')).then((value) {
              if (prefs.string('afterbaskettoorders') == '1') {
                navProcess();
              } else {
                navHome();
              }
            });
          }
          return;
        }
        appdata.basket.clear();
        appdata.basketData.clear();
        carNumberController.clear();
        appdata.basketTotal();
        if (prefs.string('afterbaskettoorders') == '1') {
          navProcess();
        } else {
          navHome();
        }
        Dialogs.show(tr('Your order was created'));
        break;
      case query_get_process_list:
        appdata.works.clear();
        for (final e in data) {
          appdata.works.add(e);
        }
        appdata.countWorksStartEnd();
        basketController.add(appdata.works);
        break;
      case query_end_order:
        getProcessList();
        break;
      case query_start_order:
        getProcessList();
        break;
    }
  }

  void correctJson(Map<String, dynamic> m) {
    for (var e in m.entries) {
      if (e.value is DateTime) {
        m![e.key] = dateTimeToStr(e.value);
      } else if (e.value is Map) {
        correctJson(e.value);
      } else if (e.value is List) {
        for (final l in e.value) {
          if (l is Map<String, dynamic>) {
            correctJson(l!);
          }
        }
      }
    }
  }

  Future<void> httpQuery(
      int code, Map<String, dynamic> params, String route) async {
    dialogController.add(0);
    correctJson(params);
    final queryResult = await WebHttpQuery(route).request(params);
    Navigator.pop(Loading.dialogContext);
    if (queryResult['status'] == 1) {
      httpOk(code, queryResult['data']);
    } else {
      dialogController.add(queryResult['data']);
    }
  }

  Future<void> httpQuery2(int code, Map<String, dynamic> params,
      {String route = HttpQuery2.networkdb, VoidCallback? callback}) async {
    Logging.write('model.httpQuery2');
    dialogController.add(0);
    Map<String, dynamic> copy = {};
    copy.addAll(params);
    if (!copy.containsKey('params')) {
      copy['params'] = <String, dynamic>{};
    }
    correctJson(copy['params']);
    Logging.write('model.httpQuery2 afterCorrectJson');
    final queryResult = await HttpQuery2(route).request(copy);
    Logging.write('model.httpQuery2 queryResult ${queryResult}' );
    Navigator.pop(Loading.dialogContext);
    if (queryResult['status'] == 1) {
      if (callback == null) {
        httpOk(code, queryResult['data']);
      } else {
        callback();
      }
    } else {
      dialogController.add(queryResult['data']);
    }
  }

  void changeFiscalMode() {
    printFiscal = !printFiscal;
    fiscalController.add(null);
  }
}
