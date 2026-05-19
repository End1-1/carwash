import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/cashdesk.dart';
import 'package:carwash/screens/cash_remains.dart';
import 'package:carwash/screens/cash_reports.dart';
import 'package:carwash/screens/cashsession.dart';
import 'package:carwash/screens/dishes.dart';
import 'package:carwash/screens/help/screen_help.dart';
import 'package:carwash/screens/history.dart' deferred as hist hide HistoryE;
import 'package:carwash/screens/login.dart';
import 'package:carwash/screens/process_end.dart';
import 'package:carwash/screens/settings.dart';
import 'package:carwash/screens/welcome.dart';
import 'package:carwash/utils/app_websocket.dart';
import 'package:carwash/utils/posprint.dart';
import 'package:carwash/utils/print_http_client.dart';
import 'package:carwash/utils/fiscal2.dart';
import 'package:carwash/utils/receipt_local_print.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/http_query.dart';
import 'package:carwash/utils/logging.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/utils/web_query.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:carwash/widgets/loading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:carwash/l10n/app_localizations.dart';

import '../status.dart';
import 'data.dart';

bool _jsonApiStatusOk(dynamic status) {
  if (status == 1 || status == true) return true;
  if (status is num && status.toInt() == 1) return true;
  final s = '$status'.trim().toLowerCase();
  return s == '1' || s == 'true';
}

class AppModel {
  static const query_call_function = -1;
  static const query_init = 1;
  static const query_create_order = 2;
  static const query_end_order = 4;
  static const query_start_order = 5;
  static const query_update_duration = 6;
  static const query_reassign_table = 7;
  static const query_payment = 8;
  static const query_print_bill = 9;
  static const query_print_fiscal = 10;

  /// Prefs key: base URL path for PHP `Order` controller (без имени метода).
  /// Пример: `/engine/v2/waiter/order` → вызов OpenTable: `.../order/open-table`.
  static const String prefKeyOrderApiRoute = 'orderapi';
  /// Базовый путь до контроллера Order (суффикс метода в kebab-case добавляется в коде).
  static const String defaultOrderApiRoute = '/engine/v2/waiter/order';

  /// `Cashbox::CheckStatus` / `Open`.
  static const String cashboxCheckStatusRoute =
      '/engine/v2/waiter/cashbox/check-status';
  static const String cashboxOpenRoute = '/engine/v2/carwash/cashbox/open';

  static const String orderFiscalLogRoute =
      '/engine/v2/waiter/order/fiscal-log';

  /// `Workstation::GetConfig` — после любого успешного логина.
  static const String workstationGetConfigRoute =
      '/engine/v2/common/workstation/get-config';

  /// Имя рабочей станции (иначе [Platform.localHostname]).
  static const String prefKeyWorkstation = 'workstation';
  /// Необязательное переопределение `station_account`; иначе — логин пользователя ОС.
  static const String prefKeyStationAccount = 'station_account';
  /// Касса для `CloseOrder` — подставляется из GetConfig (`f_config` или корень ответа).
  static const String prefKeyCashboxId = 'cashbox_id';
  /// Тип станции (`f_type`, int), по умолчанию 1.
  static const String prefKeyWorkstationType = 'workstation_type';

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
  final orderApiController = TextEditingController();
  final messageController = TextEditingController();

  final basketController = StreamController.broadcast();
  final dishesController = StreamController.broadcast();
  final dialogController = StreamController();
  final fiscalController = StreamController.broadcast();

  final AppWebSocket appWebsocket = AppWebSocket();
  final loadingDialogMessages = <int, String>{};
  late final Data appdata;

  Size? screenSize;
  var screenMultiple = 0.43;
  var printFiscal = true;
  var login = false;
  bool _orderBusy = false;
  bool get isOrderBusy => _orderBusy;
  bool _isEstimatingOrderWindow = false;
  bool get isEstimatingOrderWindow => _isEstimatingOrderWindow;
  String _lastCheckoutFingerprint = '';
  DateTime? _lastCheckoutAt;
  static const Duration _duplicateCheckoutWindow = Duration(seconds: 20);
  /// `YES` or `NO`, persisted as prefs key `usessl`.
  String settingsUseSsl = 'YES';

  /// Ответ `get-config`: слитый JSON `f_config` (после логина).
  Map<String, dynamic>? workstationConfig;
  /// Список фискальных устройств из того же ответа.
  List<dynamic> fiscalMachines = [];
  /// `fiscal_machine_id` из конфига рабочей станции (корень ответа или `f_config`) — какую строку из [fiscalMachines] использовать.
  int? _workstationFiscalMachineId;
  /// Имя принтера чека из `receipt_printer` (корень GetConfig или `f_config`) — печать на сервере.
  String? _receiptPrinterName;

  /// URL HTTP сервера печати из `print_server` (корень GetConfig или `f_config`); без схемы к подключению добавляется `http://`.
  String? _printServerUrl;

  /// Секрет для сервера печати из `print_server_key` (корень GetConfig или `f_config`).
  String? _printServerKey;

  AppModel() {
    appdata = Data(this);
    dialogController.stream.listen((event) {
      if (event is int) {
        Loading.show(loadingDialogMessages[event] ?? locale().loading);
      } else if (event is String) {
        if (event.isEmpty) {
          return;
        }
        Dialogs.show(event);
      }
    });
  }

  void configScreenSize() {
      screenMultiple = 0.2;
  }

  /// Имя пользователя в ОС, где запущено приложение (Windows: `USERNAME`, Linux/macOS: `USER` / `LOGNAME`).
  static String osLoginUserName() {
    try {
      final e = Platform.environment;
      return (e['USERNAME'] ?? e['USER'] ?? e['LOGNAME'] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  /// Параметры для [workstationGetConfigRoute]: prefs или значения по умолчанию.
  Map<String, dynamic> _workstationGetConfigBody() {
    final ws = prefs.string(prefKeyWorkstation).trim();
    final name =
        ws.isNotEmpty ? ws : (Platform.localHostname);
    final acct = prefs.string(prefKeyStationAccount).trim();
    final sysUser = osLoginUserName();
    final stationAccount =
        acct.isNotEmpty ? acct : (sysUser.isNotEmpty ? sysUser : 'unknown');
    return <String, dynamic>{
      'workstation': name,
      'station_account': stationAccount,
      'type': 6,
    };
  }

  void _applyWorkstationConfigResponse(Map<String, dynamic> r) {
    final cfg = r['f_config'];
    if (cfg is String) {
      try {
        final decoded = jsonDecode(cfg);
        workstationConfig =
            decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      } catch (_) {
        workstationConfig = null;
      }
    } else if (cfg is Map) {
      workstationConfig = Map<String, dynamic>.from(cfg);
    } else {
      workstationConfig = null;
    }

    final f = r['fiscal'];
    if (f is List) {
      fiscalMachines = List<dynamic>.from(f);
    } else {
      fiscalMachines = [];
    }

    _workstationFiscalMachineId = _parseIntFromConfig(r['fiscal_machine_id']) ??
        _parseIntFromConfig(r['f_fiscal_machine_id']);
    if (_workstationFiscalMachineId == null && workstationConfig != null) {
      _workstationFiscalMachineId = _parseIntFromConfig(
            workstationConfig!['fiscal_machine_id']) ??
          _parseIntFromConfig(workstationConfig!['f_fiscal_machine_id']);
    }

    _receiptPrinterName = _trimmedStringConfig(r['receipt_printer']);
    if (_receiptPrinterName == null && workstationConfig != null) {
      _receiptPrinterName =
          _trimmedStringConfig(workstationConfig!['receipt_printer']);
    }

    _printServerUrl = _trimmedStringConfig(r['print_server']);
    if (_printServerUrl == null && workstationConfig != null) {
      _printServerUrl =
          _trimmedStringConfig(workstationConfig!['print_server']);
    }
    if (_printServerUrl != null) {
      prefs.setString('print_server', _printServerUrl!);
    } else {
      prefs.remove('print_server');
    }

    _printServerKey = _trimmedStringConfig(r['print_server_key']);
    if (_printServerKey == null && workstationConfig != null) {
      _printServerKey =
          _trimmedStringConfig(workstationConfig!['print_server_key']);
    }
    if (_printServerKey != null) {
      prefs.setString('print_server_key', _printServerKey!);
    } else {
      prefs.remove('print_server_key');
    }

    _syncCashboxIdFromWorkstationResponse(r);
  }

  static String? _trimmedStringConfig(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _parseIntFromConfig(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  static int? _cashboxIdFromMap(Map<String, dynamic> m) {
    for (final key in ['cashbox_id', 'f_cashbox_id']) {
      if (!m.containsKey(key)) continue;
      final id = _parseIntFromConfig(m[key]);
      if (id != null) return id;
    }
    return null;
  }

  /// Берёт `cashbox_id` из корня ответа GetConfig и из слитого `f_config`, пишет в [prefKeyCashboxId].
  void _syncCashboxIdFromWorkstationResponse(Map<String, dynamic> r) {
    final fromRoot = _cashboxIdFromMap(r);
    final fromCfg =
        workstationConfig != null ? _cashboxIdFromMap(workstationConfig!) : null;
    final id = fromRoot ?? fromCfg;
    if (id != null) {
      prefs.setInt(prefKeyCashboxId, id);
    }
  }

  /// Для `CloseOrder` и др.: значение после GetConfig (или 0).
  int get cashboxIdForOrder => prefs.getInt(prefKeyCashboxId) ?? 0;

  static int? _parseSessionId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static int _cashboxSessionIdFromCheckResponse(Map<String, dynamic> r) {
    final top = _parseSessionId(r['cashbox_session_id']);
    if (top != null && top > 0) return top;
    final res = r['result'];
    if (res is Map) {
      final id = _parseSessionId(res['cashbox_session_id']);
      if (id != null && id > 0) return id;
    }
    final cs = r['cashbox_session'];
    if (cs is Map) {
      final id = _parseSessionId(cs['f_id']);
      if (id != null && id > 0) return id;
    }
    return 0;
  }

  /// После GetConfig: `check-status`, обновляет prefs `cashsession` (id или 0).
  Future<String?> syncCashboxSessionFromApi() async {
    final cid = cashboxIdForOrder;
    if (cid <= 0) {
      prefs.setInt('cashsession', 0);
      return null;
    }
    final r = await WebHttpQuery(cashboxCheckStatusRoute)
        .request(<String, dynamic>{'cashbox_id': cid});
    if (r['status'] != 1) {
      prefs.setInt('cashsession', 0);
      return r['data']?.toString() ?? 'Cashbox check-status failed';
    }
    prefs.setInt('cashsession', _cashboxSessionIdFromCheckResponse(r));
    return null;
  }

  /// Вызывается после успешного логина. Возвращает текст ошибки или `null`.
  Future<String?> fetchWorkstationConfig() async {
    final r = await WebHttpQuery(workstationGetConfigRoute)
        .request(_workstationGetConfigBody());
    if (r['status'] != 1) {
      return r['data']?.toString() ?? 'GetConfig failed';
    }
    _applyWorkstationConfigResponse(r);
    return null;
  }

  Future<String> initModel() async {
    // dialogController.add(1);
    loadingDialogMessages[0] = locale().loading;
    loadingDialogMessages[1] = locale().printingFiscal;
    loadingDialogMessages[2] = locale().printingBill;
    final loginResult = await WebHttpQuery('/engine/v2/worker/user-login/hash-login')
        .request({'token': prefs.string('token')});
    if (loginResult['status'] == 1) {
      login = true;
      prefs.setInt('user_group', loginResult['userdata']['f_group']);
    //  prefs.setInt('cashsession', loginResult['data']['cashsession']['f_id']);

      final wsErr = await fetchWorkstationConfig();
      if (wsErr != null) {
        dialogController.add(wsErr);
        return wsErr;
      }

      final queryResult = await WebHttpQuery('/engine/v2/carwash/init-data/get')
          .request({'f_menu': int.tryParse(prefs.string('menucode')) ?? 0});

      if (queryResult['status'] == 1) {
        httpOk(query_init,  queryResult['data']);
        final cashErr = await syncCashboxSessionFromApi();
        if (cashErr != null) {
          return cashErr;
        }
        return '';
      } else {
        dialogController.add(queryResult['data']);
        return queryResult['data'];
      }
    }

    return '';


  }

  Future<void> tryLogin(String? pin) async {
    final result = await WebHttpQuery('/engine/v2/worker/user-login/pin-login')
        .request({'pin': pin ?? '', 'phone':'+37455555220'});
    if (result['status'] == 1) {
      login = true;
      prefs.setString('token', result['token']);
      prefs.setInt('user_group', result['userdata']['f_group']);
     // prefs.setInt('cashsession', result['cashsession']);
      final wsErr = await fetchWorkstationConfig();
      if (wsErr != null) {
        dialogController.add(wsErr);
        return;
      }
      if (cashboxIdForOrder <= 0) {
        prefs.setInt('cashsession', 0);
        dialogController.add(locale().cashboxNotConfigured);
        navCashdeskAsRoot();
        return;
      }
      final cashErr = await syncCashboxSessionFromApi();
      if (cashErr != null) {
        dialogController.add(cashErr);
        return;
      }
      if ((prefs.getInt('cashsession') ?? 0) > 0) {
        navHome();
      } else {
        navCashdeskAsRoot();
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
    unawaited(_navHomeAsync());
  }

  Future<void> _navHomeAsync() async {
    if (!login) {
      navLogin();
      return;
    }
    final ctx = Prefs.navigatorKey.currentContext;
    if (ctx == null) return;

    final cashErr = await syncCashboxSessionFromApi();
    if (cashErr != null) {
      dialogController.add(cashErr);
    }

    if (cashboxIdForOrder <= 0) {
      prefs.setInt('cashsession', 0);
      dialogController.add(locale().cashboxNotConfigured);
      if (!ctx.mounted) return;
      navCashdeskAsRoot();
      return;
    }

    if ((prefs.getInt('cashsession') ?? 0) <= 0) {
      if (!ctx.mounted) return;
      navCashdeskAsRoot();
      return;
    }

    if (!ctx.mounted) return;
    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(builder: (builder) => WelcomeScreen(this)),
      (r) => false,
    );
  }

  /// Полная замена стека: экран кассы (отчёты). Без активной смены на экране
  /// можно перейти к открытию смены ([CashSession]).
  void navCashdeskAsRoot() {
    unawaited(_navCashdeskAsRootAsync());
  }

  Future<void> _navCashdeskAsRootAsync() async {
    final ctx = Prefs.navigatorKey.currentContext;
    if (ctx == null) return;
    await CashdeskScreen.syncSessionAndApplyFilter(this);
    if (!ctx.mounted) return;
    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(builder: (builder) => CashdeskScreen(this)),
      (r) => false,
    );
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
    BlocProvider.of<AppAnimateBloc>(prefs.context()).add(AppAnimateEvent());
    Dialogs.getPin().then((value) {
      if ((value ?? '') == '1981') {
        settingsServerAddressController.text = prefs.string('websocket');
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
        orderApiController.text = prefs.string(prefKeyOrderApiRoute);
        settingsUseSsl =
            prefs.string('usessl').toUpperCase() == 'NO' ? 'NO' : 'YES';
        Navigator.push(Prefs.navigatorKey.currentContext!,
            MaterialPageRoute(builder: (builder) => SettingsScreen(this)));
      }
    });
  }

  void navCashdesk() {
    unawaited(_navCashdeskPushAsync());
  }

  Future<void> _navCashdeskPushAsync() async {
    final ctx = Prefs.navigatorKey.currentContext;
    if (ctx == null) return;
    await CashdeskScreen.syncSessionAndApplyFilter(this);
    if (!ctx.mounted) return;
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (builder) => CashdeskScreen(this)),
    );
  }

  void navCashReports() {
    unawaited(_navCashReportsPushAsync());
  }

  void navCashRemains() {
    final ctx = Prefs.navigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (builder) => CashRemainsScreen(this)),
    );
  }

  Future<void> _navCashReportsPushAsync() async {
    final ctx = Prefs.navigatorKey.currentContext;
    if (ctx == null) return;
    await CashReportsScreen.syncSessionAndApplyFilter(this);
    if (!ctx.mounted) return;
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (builder) => CashReportsScreen(this)),
    );
  }

  void navHistory() {
    unawaited(_navHistoryPushAsync());
  }

  Future<void> _navHistoryPushAsync() async {
    await hist.loadLibrary();
    final ctx = Prefs.navigatorKey.currentContext;
    if (ctx == null) return;
    await syncCashboxSessionFromApi();
    if (!ctx.mounted) return;
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (builder) => hist.HistoryScreen(this)),
    );
  }

  void navHistoryGoodsProcess() {
    unawaited(_navHistoryGoodsPushAsync());
  }

  Future<void> _navHistoryGoodsPushAsync() async {
    await hist.loadLibrary();
    final ctx = Prefs.navigatorKey.currentContext;
    if (ctx == null) return;
    await syncCashboxSessionFromApi();
    if (!ctx.mounted) return;
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (builder) => hist.HistoryScreen(
          this,
          initialMode: hist.HistoryViewMode.goodsDoneParking,
        ),
      ),
    );
  }

  void navStatus() {
    Navigator.pop(prefs.context());
    Navigator.push(prefs.context(),
        MaterialPageRoute(builder: (builder) => StatusScreen(this)));
  }

  void saveSettings() {
    prefs.setString('websocket', settingsServerAddressController.text);
    prefs.setString(
        'webserveraddress', settingsWebServerAddressController.text);
    prefs.setString('menucode', menuCodeController.text);
    prefs.setString('appmode', modeController.text);
    prefs.setString('showunpaid', showUnpaidController.text);
    prefs.setString('table', tableController.text);
    prefs.setString('title', titleController.text);
    prefs.setString('config', configController.text);
    prefs.setString('afterbaskettoorders', afterBasketToOrdersController.text);
    prefs.setString(prefKeyOrderApiRoute, orderApiController.text);
    prefs.setString('usessl', settingsUseSsl);
    initModel().then((value) {
      if (!login) {
        navLogin();
        return;
      }
      if (value.isNotEmpty) {
        return;
      }
      if ((prefs.getInt('cashsession') ?? 0) > 0) {
        navHome();
      } else {
        navCashdeskAsRoot();
      }
    });
  }

  void closeQuestionDialog() {
    BlocProvider.of<QuestionBloc>(prefs.context()).add(QuestionEvent());
  }

  void navDishes(filter) {
    ensureCashSessionBeforeOrder().then((ok) {
      if (!ok) {
        return;
      }
      Navigator.push(Prefs.navigatorKey.currentContext!,
          MaterialPageRoute(builder: (builder) => DishesScreen(this, filter)));
    });
  }

  void closeErrorDialog() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEvent());
  }

  AppLocalizations locale() {
    return AppLocalizations.of(prefs.context())!;
  }

  Future<void> removeOrder(Map<String, dynamic> data) async {
    WebHttpQuery('/engine/carwash/remove-order.php')
        .request(data)
        .then((value) {
    });
  }

  Future<void> changeStateOfProcess(Map<String, dynamic> data) async {
    WebHttpQuery('/engine/carwash/status.php').request(data).then((value) {
    });
  }

  void callStaff() {
    navHelp();
  }

  void addToBasket(Map<String, dynamic> data) {
    if (_orderBusy) {
      return;
    }
    data['f_uuid'] = const Uuid().v1().toString();
    appdata.basket.add(data);
    appdata.basketTotal();
    basketController.add(appdata.basket.length);
    unawaited(refreshBasketOrderWindowFromServer());
  }

  void processOrder() {
    if (_orderBusy) {
      return;
    }
    final fp = _checkoutFingerprint();
    final now = DateTime.now();
    if (_lastCheckoutFingerprint == fp &&
        _lastCheckoutAt != null &&
        now.difference(_lastCheckoutAt!) < _duplicateCheckoutWindow) {
      dialogController.add('Order is already being processed. Please wait.');
      return;
    }
    _lastCheckoutFingerprint = fp;
    _lastCheckoutAt = now;
    _setOrderBusy(true);
    unawaited(() async {
      var loadingShown = false;
      try {
        final ok = await ensureCashSessionBeforeOrder();
        if (!ok) {
          return;
        }
        if (carNumberController.text.isEmpty) {
          Dialogs.show('Նշեք մեքենայի պետհամարանիշը');
          return;
        }
        if (appdata.basket.isEmpty) {
          Dialogs.show(locale().yourBasketIsEmpty);
          return;
        }
        await refreshBasketOrderWindowFromServer();
        await Loading.showUntilDisplayed(locale().loading);
        loadingShown = true;
        final outcome = await _runPhpOrderCheckout();
        if (outcome.error != null) {
          dialogController.add(outcome.error!);
          return;
        }
        if (outcome.usedLocalFiscal) {
          httpOk(query_print_fiscal, outcome.fiscalBundle);
        } else {
          httpOk(query_create_order, outcome.fiscalBundle!);
        }
      } catch (e, st) {
        // ignore: avoid_print
        print('[/order] exception: $e\n$st');
        dialogController.add('Order failed: $e');
      } finally {
        if (loadingShown) {
          Loading.dismiss();
        }
        _setOrderBusy(false);
      }
    }());
  }

  void _setOrderBusy(bool value) {
    if (_orderBusy == value) return;
    _orderBusy = value;
    // Trigger rebuilds for basket/payment/order controls.
    basketController.add(null);
    fiscalController.add(null);
  }

  String _checkoutFingerprint() {
    final car = carNumberController.text.trim();
    final items = List<Map<String, dynamic>>.from(appdata.basket);
    items.sort((a, b) =>
        '${a['f_dish']}:${a['f_uuid']}'.compareTo('${b['f_dish']}:${b['f_uuid']}'));
    final itemFp = items
        .map((e) =>
            '${e['f_dish']}:${e['f_qty']}:${e['f_price']}:${e['f_cooking_time']}')
        .join('|');
    final bd = appdata.basketData;
    return [
      car,
      itemFp,
      '${bd['f_amounttotal'] ?? 0}',
      '${bd['f_amountcash'] ?? 0}',
      '${bd['f_amountcard'] ?? 0}',
      '${bd['f_amountidram'] ?? 0}',
      '${bd['f_amountother'] ?? 0}',
      '$printFiscal',
    ].join('#');
  }

  Future<bool> ensureCashSessionBeforeOrder() async {
    if (cashboxIdForOrder <= 0) {
      Dialogs.show(locale().cashboxNotConfigured);
      navCashdeskAsRoot();
      return false;
    }
    final cashErr = await syncCashboxSessionFromApi();
    if (cashErr != null) {
      dialogController.add(cashErr);
    }
    if ((prefs.getInt('cashsession') ?? 0) <= 0) {
      Dialogs.show(locale().openCashSessionBeforeOrder).then((_) {
        navCashdeskAsRoot();
      });
      return false;
    }
    return true;
  }

  String _orderApiBasePath() {
    var p = prefs.string(prefKeyOrderApiRoute).trim();
    if (p.isEmpty) p = defaultOrderApiRoute;
    if (!p.startsWith('/')) p = '/$p';
    while (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  /// PascalCase как в PHP-методе → сегмент URL (open-table, add-dish, …).
  static String orderMethodToUrlSegment(String pascalMethod) {
    return pascalMethod
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}-${m[2]}')
        .toLowerCase();
  }

  /// POST на `{base}/{kebab-method}`; тело — только параметры метода (`$jsonParams` на бэкенде).
  Future<Map<String, dynamic>> _orderApiInvoke(
    String method,
    Map<String, dynamic> params, {
    int timeoutSeconds = 120,
  }) async {
    final route = '${_orderApiBasePath()}/${orderMethodToUrlSegment(method)}';
    if (kDebugMode) {
      print('Order API POST $route ${jsonEncode(params)}');
    }
    return WebHttpQuery(route, timeoutSeconds: timeoutSeconds).request(params);
  }

  Map<String, dynamic>? _orderFromApiResponse(Map<String, dynamic> json) {
    final o = json['order'];
    if (o is Map<String, dynamic>) return o;
    if (o is Map) return Map<String, dynamic>.from(o);
    final r = json['result'];
    if (r is Map) {
      final ro = r['order'];
      if (ro is Map<String, dynamic>) return ro;
      if (ro is Map) return Map<String, dynamic>.from(ro);
    }
    return null;
  }

  String? _orderApiErrorMessage(Map<String, dynamic> json) {
    if (_jsonApiStatusOk(json['status'])) return null;
    final d = json['data'];
    if (d is String) return d;
    if (d != null) return d.toString();
    return 'Order API error';
  }

  /// Минуты из позиции корзины (`+`/`-` в [DishBasket]); для `AddDish` / `f_data`.
  int _basketCookingMinutes(Map<String, dynamic> e) {
    final v = e['f_cooking_time'];
    if (v == null) return 0;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<void> refreshBasketOrderWindowFromServer() async {
    final basket = List<Map<String, dynamic>>.from(appdata.basket);
    if (basket.isEmpty) return;
    if (_isEstimatingOrderWindow) return;
    _isEstimatingOrderWindow = true;
    try {
      var maxCook = 0;
      for (final e in basket) {
        final m = _basketCookingMinutes(e);
        if (m > maxCook) maxCook = m;
      }
      if (maxCook <= 0) {
        dialogController.add('Invalid basket: f_cooking_time required');
        return;
      }
      final now = DateTime.now();
      final end = now.add(Duration(minutes: maxCook));
      final startStr = dateTimeToStr(now);
      final endStr = dateTimeToStr(end);
      for (final e in basket) {
        e['f_cooking_start'] = startStr;
        e['f_cooking_end'] = endStr;
      }
      basketController.add(null);
    } finally {
      _isEstimatingOrderWindow = false;
    }
  }

  /// Заказ для диалога оплаты (`QueryOrder` → `…/query-order`): суммы, блюда для фиска,
  /// `f_data` (номер и т.д.). Статус готовки / OGP сюда не входит — его не откуда взять.
  Future<Map<String, dynamic>?> fetchOrderForPayment(String headerId) async {
    final r = await _orderApiInvoke('QueryOrder', {'id': headerId});
    if (!_jsonApiStatusOk(r['status'])) return null;
    final o = _orderFromApiResponse(r);
    if (o != null) return o;
    final d = r['data'];
    if (d is Map) {
      final dm = Map<String, dynamic>.from(d);
      final o2 = _orderFromApiResponse(dm);
      if (o2 != null) return o2;
      final inner = dm['order'] ?? dm['data'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
    }
    return null;
  }

  /// Госномер из заказа для отображения (f_data / f_car_number), без изменения [carNumberController].
  String carPlateFromOrderMap(Map<String, dynamic> o) {
    final fd = o['f_data'];
    if (fd is String && fd.isNotEmpty) {
      try {
        final j = jsonDecode(fd);
        if (j is Map && j['f_car_number'] != null) {
          return '${j['f_car_number']}'.trim();
        }
      } catch (_) {}
    }
    if (fd is Map && fd['f_car_number'] != null) {
      return '${fd['f_car_number']}'.trim();
    }
    return '${o['f_car_number'] ?? ''}'.trim();
  }

  List<Map<String, dynamic>> _basketLinesForFiscalFromOrder(
      Map<String, dynamic> order) {
    dynamic raw = order['dishes'];
    if (raw is! List || raw.isEmpty) {
      raw = order['precheck_dishes'];
    }
    if (raw is List && raw.isNotEmpty) {
      final out = <Map<String, dynamic>>[];
      for (final e in raw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final price = (m['f_price'] as num?)?.toDouble() ??
            (m['f_sum'] as num?)?.toDouble() ??
            0.0;
        final qty = (m['f_qty'] as num?)?.toDouble() ?? 1.0;
        final name =
            '${m['f_dish_name'] ?? m['f_name'] ?? m['name'] ?? ''}'.trim();
        out.add(<String, dynamic>{
          'f_dish_name': name.isEmpty ? '—' : name,
          'f_price': price,
          'f_qty': qty,
          'f_department': m['f_department'] ?? 1,
          'f_adgt': m['f_adgt'],
          'f_id': m['f_id'] ?? m['f_dish'] ?? 0,
          'f_data': m['f_data'],
        });
      }
      if (out.isNotEmpty) return out;
    }
    final total = (order['f_amounttotal'] as num?)?.toDouble() ??
        double.tryParse('${order['f_amounttotal'] ?? 0}') ??
        0.0;
    final fd = order['f_data'];
    String name = 'Service';
    if (fd is String && fd.isNotEmpty) {
      try {
        final j = jsonDecode(fd);
        if (j is Map && j['f_comment'] != null) {
          name = '${j['f_comment']}'.trim();
        }
      } catch (_) {}
    } else if (fd is Map && fd['f_comment'] != null) {
      name = '${fd['f_comment']}'.trim();
    }
    if (name.isEmpty) name = 'Service';
    return [
      <String, dynamic>{
        'f_dish_name': name,
        'f_price': total,
        'f_qty': 1.0,
        'f_department': 1,
        'f_adgt': '',
        'f_id': 0,
      }
    ];
  }

  /// Оплата «прочее» реальными способами: фискалка → [ModifyOrder].
  /// Для завершённых заказов (3/4 или 3/5) в [ModifyOrder] передаём [o_goods_process_status]
  /// 5/7, чтобы сервер закрыл этап и строка пропала с goods-in-progress.
  /// Для этапов до 3 — ту же пару статус/подстатус (1/1, 2/2, 2/3), кроме рассинхрона БД:
  /// подстатусы 4 и 5 допустимы только при `f_status == 3`; иначе получалась недопустимая
  /// пара вроде 2/4 и заказ оставался в «ожидает оплату».
  Future<String?> payComplimentaryOrderWithRealPayment({
    required String headerId,
    required Map<String, dynamic> orderSnapshot,
    required double cash,
    required double card,
    required double idram,
    int? processStatus,
    int? processSubstatus,
  }) async {
    var ps = processStatus;
    var pss = processSubstatus;
    if (ps != null && pss != null && (pss == 4 || pss == 5) && ps < 3) {
      ps = 3;
    }
    final total = (orderSnapshot['f_amounttotal'] as num?)?.toDouble() ??
        double.tryParse('${orderSnapshot['f_amounttotal'] ?? 0}') ??
        0.0;
    final sum = cash + card + idram;
    if (total <= 0) return 'Invalid order total';
    if ((sum - total).abs() > 0.02) {
      return locale().historyPayTotalMismatch;
    }
    final okSession = await ensureCashSessionBeforeOrder();
    if (!okSession) {
      return locale().openCashSessionBeforeOrder;
    }
    final basket = _basketLinesForFiscalFromOrder(orderSnapshot);
    final bd = <String, dynamic>{
      'f_amounttotal': total,
      'f_amountcash': cash,
      'f_amountcard': card,
      'f_amountidram': idram,
      'f_amountother': 0,
    };
    Map<String, dynamic> fiscalForModify;
    FiscalPrintResult? fiscalRes;
    if (printFiscal) {
      fiscalRes = await _printFiscalReceiptViaFiscalServer(
        basket: basket,
        bd: bd,
        orderHeaderId: headerId,
      );
      if (!fiscalRes.isOk) {
        unawaited(_postOrderFiscalLog(headerId, fiscalRes));
        final msg = fiscalRes.error.isNotEmpty
            ? fiscalRes.error
            : '${locale().printFiscalFailed} (${fiscalRes.result})';
        return msg;
      }
      fiscalForModify = <String, dynamic>{
        'in': fiscalRes.inJson,
        'out': fiscalRes.outJson ?? <String, dynamic>{},
        'err': fiscalRes.error,
        'error': fiscalRes.error,
        'result': fiscalRes.result,
      };
    } else {
      fiscalForModify = <String, dynamic>{
        'in': <String, dynamic>{},
        'out': <String, dynamic>{},
        'error': '',
        'err': '',
        'result': 0,
      };
    }
    final baseComment = '${orderSnapshot['f_comment'] ?? ''}'.trim();
    final carNumber = carPlateFromOrderMap(orderSnapshot).trim();
    var paymentComment = baseComment;
    if (carNumber.isNotEmpty && !baseComment.contains(carNumber)) {
      paymentComment =
          baseComment.isEmpty ? carNumber : '$baseComment | $carNumber';
    }
    final mod = await _orderApiInvoke('ModifyOrder', {
      'id': headerId,
      'cashbox_id': cashboxIdForOrder,
      'it_payment': true,
      if (paymentComment.isNotEmpty) 'f_comment': paymentComment,
      'f_amount_other': 0.0,
      'f_amount_cash': cash,
      'f_amount_card': card,
      'f_amount_idram': idram,
      if (ps != null && pss != null && ps < 3)
        'o_goods_process_status': <String, dynamic>{
          'f_status': ps,
          'f_substatus': pss,
        }
      else if (ps == 3 && (pss == 4 || pss == 5))
        'o_goods_process_status': <String, dynamic>{
          'f_status': 5,
          'f_substatus': 7,
        },
      'fiscal': fiscalForModify,
    });
    final modErr = _orderApiErrorMessage(mod);
    if (modErr != null) {
      return modErr;
    }
    if (printFiscal && fiscalRes != null) {
      unawaited(_postOrderFiscalLog(headerId, fiscalRes));
    }
    return null;
  }

  /// Строка фискальной машины из [fiscalMachines] по [_workstationFiscalMachineId], иначе первая запись (совместимость).
  Map<String, dynamic>? _fiscalMachineRowForWorkstation() {
    if (fiscalMachines.isEmpty) return null;
    final wanted = _workstationFiscalMachineId;
    if (wanted != null) {
      for (final raw in fiscalMachines) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final rowId = _parseIntFromConfig(
            row['f_id'] ?? row['id'] ?? row['fiscal_machine_id']);
        if (rowId != null && rowId == wanted) {
          return row;
        }
      }
      return null;
    }
    final first = fiscalMachines.first;
    if (first is! Map) return null;
    return Map<String, dynamic>.from(first);
  }

  /// Параметры TCP к фискальному модулю из выбранной строки [fiscalMachines] (GetConfig).
  ({String host, int port, String password, String op, String pin, String useExtPos})?
      _fiscalTcpParams() {
    final m = _fiscalMachineRowForWorkstation();
    if (m == null) return null;
    final host =
        '${m['f_ip'] ?? m['f_host'] ?? m['f_address'] ?? ''}'.trim();
    if (host.isEmpty) return null;
    final port = int.tryParse('${m['f_port'] ?? 1025}') ?? 1025;
    final password =
        '${m['f_password'] ?? m['f_pass'] ?? m['f_tax_password'] ?? ''}';
    if (password.isEmpty) return null;
    final op =
        '${m['f_operator'] ?? m['f_opcode'] ?? m['f_tax_cashier'] ?? '3'}';
    final pin =
        '${m['f_operator_pin'] ?? m['f_oppin'] ?? m['f_tax_pin'] ?? '3'}';
    final useExtPos =
        '${m['f_user_ext_pos'] ?? m['f_use_ext_pos'] ?? 'false'}';
    return (
      host: host,
      port: port,
      password: password,
      op: op,
      pin: pin,
      useExtPos: useExtPos,
    );
  }

  Future<void> _postOrderFiscalLog(String orderId, FiscalPrintResult r) async {
    try {
      await WebHttpQuery(orderFiscalLogRoute, timeoutSeconds: 5).request(
        <String, dynamic>{
          'id': orderId,
          'in': r.inJson,
          'out': r.outJson ?? <String, dynamic>{},
          'error': r.error,
          'result': r.result,
        },
      );
    } catch (_) {/* ignore */}
  }

  String? _missingAdgtDishName(List<Map<String, dynamic>> basket) {
    for (final e in basket) {
      final adgt = '${e['f_adgt'] ?? ''}'.trim();
      if (adgt.isEmpty) {
        final name = '${e['f_dish_name'] ?? e['f_name'] ?? e['name'] ?? ''}'.trim();
        return name.isEmpty ? '—' : name;
      }
    }
    return null;
  }

  Uri? _fiscalServerUriFromPrintServerUrl(String printServerUrl) {
    final base = resolvePrintServerUri(printServerUrl);
    if (base == null) return null;
    var p = base.path;
    // Expected URLs:
    // - .../print -> .../fiscal
    // - ...:8181:/print (normalized by resolvePrintServerUri) -> .../fiscal
    if (p.endsWith('/print')) {
      p = p.substring(0, p.length - '/print'.length) + '/fiscal';
    } else if (p.endsWith('/print/')) {
      p = p.substring(0, p.length - '/print/'.length) + '/fiscal';
    } else if (p.isEmpty || p == '/') {
      p = '/fiscal';
    } else {
      // If config points somewhere else, just append.
      p = p.endsWith('/') ? '${p}fiscal' : '$p/fiscal';
    }
    return base.replace(path: p);
  }

  Future<FiscalPrintResult> _printFiscalReceiptViaFiscalServer({
    required List<Map<String, dynamic>> basket,
    required Map<String, dynamic> bd,
    /// `o_header.f_id` — в JSON на сервер печати как `order` (см. FiscalLogSession в Qt).
    required String orderHeaderId,
    void Function(String message)? onStep,
  }) async {
    final oid = orderHeaderId.trim();
    if (oid.isEmpty) {
      return FiscalPrintResult(
        inJson: <String, dynamic>{},
        error: 'Missing o_header.f_id for fiscal print',
        result: -14,
      );
    }

    final missingAdgtName = _missingAdgtDishName(basket);
    if (missingAdgtName != null) {
      return FiscalPrintResult(
        inJson: <String, dynamic>{},
        error: 'Missing f_adgt for dish: $missingAdgtName',
        result: -13,
      );
    }

    final fc = _fiscalTcpParams();
    if (fc == null) {
      return FiscalPrintResult(
        inJson: <String, dynamic>{},
        error: locale().fiscalNotConfigured,
        result: -10,
      );
    }

    final printUrl =
        _printServerUrl ?? _trimmedStringConfig(prefs.string('print_server'));
    if (printUrl == null || printUrl.isEmpty) {
      return FiscalPrintResult(
        inJson: <String, dynamic>{},
        error: locale().printServerNotConfigured,
        result: -11,
      );
    }

    final fiscalUri = _fiscalServerUriFromPrintServerUrl(printUrl);
    if (fiscalUri == null) {
      return FiscalPrintResult(
        inJson: <String, dynamic>{},
        error: 'Invalid fiscal server URL derived from print_server',
        result: -12,
      );
    }

    onStep?.call('Fiscal server: POST ${fiscalUri.toString()}');

    final dishes = <Map<String, dynamic>>[];
    int depDefault = 1;

    for (final e in basket) {
      final dep =
          int.tryParse('${e['f_department'] ?? e['f_fiscal_dep'] ?? 1}') ?? 1;
      depDefault = depDefault == 1 ? dep : depDefault;
      final adgt = '${e['f_adgt'] ?? ''}'.trim();
      final pid = int.tryParse('${e['f_id']}') ?? 0;
      final name = (e['f_dish_name'] ?? '').toString();
      final price = (e['f_price'] as num?)?.toDouble() ?? 0.0;
      final qty = (e['f_qty'] as num?)?.toDouble() ?? 1.0;

      var discountPct = 0.0;
      final fd = e['f_data'];
      Map<String, dynamic>? fdm;
      if (fd is String && fd.isNotEmpty) {
        try {
          fdm = jsonDecode(fd) as Map<String, dynamic>?;
        } catch (_) {}
      } else if (fd is Map) {
        fdm = Map<String, dynamic>.from(fd);
      }
      final df = fdm?['f_discount_factor'];
      if (df is num) discountPct = df.toDouble() * 100;

      dishes.add(<String, dynamic>{
        'dep': dep,
        'adgt': adgt,
        'id': pid,
        'name': name,
        'price': price,
        'qty': qty,
        'discount': discountPct,
      });
    }

    final cash = (bd['f_amountcash'] as num?)?.toDouble() ?? 0.0;
    final card = (bd['f_amountcard'] as num?)?.toDouble() ?? 0.0;
    final idram = (bd['f_amountidram'] as num?)?.toDouble() ?? 0.0;
    final paidCard = card + idram;
    final paidPrepaid = 0.0;

    final payload = <String, dynamic>{
      'order': oid,
      'fiscal': <String, dynamic>{
        'ip': fc.host,
        'port': fc.port,
        'password': fc.password,
        'useextpos': fc.useExtPos,
        'opcode': fc.op,
        'oppin': fc.pin,
        'dep_default': depDefault,
      },
      'dishes': dishes,
      'paid_card': paidCard,
      'paid_prepaid': paidPrepaid,
      'paid_cash': cash
    };

    onStep?.call('Fiscal server: send data…');
    final resp = await postPrintServerJsonAny(
      url: fiscalUri.toString(),
      body: payload,
      timeout: const Duration(seconds: 90),
    );
    final httpStatus = resp['_httpStatus'];
    onStep?.call('Fiscal server: HTTP $httpStatus');

    final result = resp['result'];
    final resultInt = result is num ? result.toInt() : int.tryParse('$result') ?? -1;

    final inJsonRaw = resp['in'];
    final outJsonRaw = resp['out'];

    final inJson = inJsonRaw is Map
        ? Map<String, dynamic>.from(inJsonRaw)
        : <String, dynamic>{};
    final outJson = outJsonRaw is Map
        ? Map<String, dynamic>.from(outJsonRaw)
        : null;

    final error = resp['error']?.toString() ?? '';
    return FiscalPrintResult(
      inJson: inJson,
      outJson: outJson,
      error: error,
      result: resultInt,
    );
  }

  /// Car wash checkout via PHP `Order`: OpenTable → AddDish → SaveData → SetAmount → CloseOrder.
  Future<_PhpOrderOutcome> _runPhpOrderCheckout() async {
    // Server-side locksrc is used for logging/tracing; send hostname instead of UUID.
    final lockSrc = Platform.localHostname;
    final table = int.tryParse(prefs.string('table')) ?? 1;
    final carNumber = carNumberController.text.trim();

    void logOrderStep(String message) {
      final ts = DateTime.now().toIso8601String();
      // In release this will still go to stdout; on devices it helps correlate with backend logs.
      // ignore: avoid_print
      print('[/order] [$ts] $message');
    }

    /// Updates console logs for each step.
    ///
    /// We intentionally do NOT reopen/pop Loading dialog here to avoid
    /// Navigator assertions when many async steps fail/timeout.
    /// UI will keep showing the initial Loading dialog; detailed timing is
    /// available in stdout: `[/order] ...`.
    void setOrderLoading(String text) {
      logOrderStep(text);
      loadingDialogMessages[0] = text;
    }

    Future<T> step<T>(String text, Future<T> Function() action) async {
      setOrderLoading(text);
      final sw = Stopwatch()..start();
      try {
        final res = await action();
        logOrderStep('$text done (${sw.elapsedMilliseconds}ms)');
        return res;
      } catch (e) {
        logOrderStep('$text failed after ${sw.elapsedMilliseconds}ms: $e');
        rethrow;
      }
    }

    Future<void> unlock([String? headerId]) async {
      final p = <String, dynamic>{
        'locksrc': lockSrc,
        'empty_order': false,
      };
      if (headerId != null) p['id'] = headerId;
      try {
        await _orderApiInvoke('UnlockTable', p, timeoutSeconds: 30);
      } catch (_) {/* ignore */}
    }

    final openRes = await step('OpenTable table=$table', () {
      return _orderApiInvoke(
        'OpenTable',
        {
          'table': table,
          'cashbox_id': cashboxIdForOrder,
          'locksrc': lockSrc,
          'create_empty': true,
        },
        timeoutSeconds: 30,
      );
    });
    var err = _orderApiErrorMessage(openRes);
    if (err != null) {
      await unlock();
      return _PhpOrderOutcome.fail(err);
    }

    var order = _orderFromApiResponse(openRes);
    final openHeaderId = order?['f_id']?.toString();
    if (openHeaderId == null || openHeaderId.isEmpty) {
      await unlock();
      return _PhpOrderOutcome.fail('OpenTable: missing order id');
    }
    var headerId = openHeaderId;

    var row = 100;
    for (final e in List<Map<String, dynamic>>.from(appdata.basket)) {
      final dishId = e['f_dish'];
      final cookingTime = _basketCookingMinutes(e);
      final addRes = await step(
        'AddDish row=$row dish=$dishId',
        () {
          return _orderApiInvoke('AddDish', {
            'table': table,
            'cashbox_id': cashboxIdForOrder,
            'dish': dishId,
            'qty': e['f_qty'] ?? 1,
            'price': e['f_price'] ?? 0,
            'type': e['f_order_type'] ?? 1,
            'store': e['f_store'] ?? 1,
            'row': row,
            'print1': e['f_print1'] ?? '',
            'print2': e['f_print2'] ?? '',
            'dish_name': e['f_dish_name'],
            'shift_rows': false,
            if (cookingTime > 0) 'f_cooking_time': cookingTime,
            'f_data': <String, dynamic>{
              // CountAmounts() only includes lines with f_printed — self-service POS skips kitchen print.
              'f_printed': true,
              'f_comment': e['f_comment'] ?? '',
              if (cookingTime > 0) 'f_cooking_time': cookingTime,
              if ('${e['f_cooking_start'] ?? ''}'.isNotEmpty)
                'f_cooking_start': e['f_cooking_start'],
              if ('${e['f_cooking_end'] ?? ''}'.isNotEmpty)
                'f_cooking_end': e['f_cooking_end'],
            },
          });
        },
      );
      err = _orderApiErrorMessage(addRes);
      if (err != null) {
        await unlock(headerId);
        return _PhpOrderOutcome.fail(err);
      }
      order = _orderFromApiResponse(addRes) ?? order;
      final nextId = order?['f_id']?.toString();
      if (nextId != null && nextId.isNotEmpty) {
        headerId = nextId;
      }
      row += 100;
    }

    final saveRes = await step('SaveData car_number=$carNumber', () {
      return _orderApiInvoke('SaveData', {
        'id': headerId,
        'data': <String, dynamic>{
          'f_car_number': carNumber,
          'f_comment': carNumber,
        },
      });
    });
    err = _orderApiErrorMessage(saveRes);
    if (err != null) {
      await unlock(headerId);
      return _PhpOrderOutcome.fail(err);
    }
    order = _orderFromApiResponse(saveRes) ?? order;

    final bd = appdata.basketData;
    final payMap = <String, double>{
      'f_amount_cash': ((bd['f_amountcash'] ?? 0) as num).toDouble(),
      'f_amount_card': ((bd['f_amountcard'] ?? 0) as num).toDouble(),
      'f_amount_idram': ((bd['f_amountidram'] ?? 0) as num).toDouble(),
      'f_amount_other': ((bd['f_amountother'] ?? 0) as num).toDouble(),
    };
    for (final pe in payMap.entries) {
      if (pe.value <= 0) continue;
      final setRes = await step(
        'SetAmount id=$headerId field=${pe.key} amount=${pe.value}',
        () {
          return _orderApiInvoke('SetAmount', {
            'id': headerId,
            'payment_field': pe.key,
            'amount': pe.value,
          });
        },
      );
      err = _orderApiErrorMessage(setRes);
      if (err != null) {
        await unlock(headerId);
        return _PhpOrderOutcome.fail(err);
      }
      order = _orderFromApiResponse(setRes) ?? order;
    }

    var usedLocalFiscal = false;
    Map<String, dynamic>? fiscalOutForReceipt;
    Map<String, dynamic> fiscalForClose = <String, dynamic>{
      'in': <String, dynamic>{},
      'out': <String, dynamic>{},
      'error': '',
      'err': '',
      'result': 0,
    };

    if (printFiscal) {
      final fiscalRes = await step('Print fiscal receipt (server)', () async {
        return await _printFiscalReceiptViaFiscalServer(
          basket: List<Map<String, dynamic>>.from(appdata.basket),
          bd: bd,
          orderHeaderId: headerId,
          onStep: setOrderLoading,
        );
      });
      if (!fiscalRes.isOk) {
        // Don't block order flow on log sending (can hang on network).
        setOrderLoading('Post fiscal log (error) (non-blocking)');
        unawaited(_postOrderFiscalLog(headerId, fiscalRes));
        // Don't block UI on UnlockTable either.
        setOrderLoading('UnlockTable after fiscal fail (non-blocking)');
        unawaited(unlock(headerId));
        final msg = fiscalRes.error.isNotEmpty
            ? fiscalRes.error
            : '${locale().printFiscalFailed} (${fiscalRes.result})';
        return _PhpOrderOutcome.fail(msg);
      }
      usedLocalFiscal = true;
      fiscalOutForReceipt = fiscalRes.outJson;
      fiscalForClose = <String, dynamic>{
        'in': fiscalRes.inJson,
        'out': fiscalRes.outJson ?? <String, dynamic>{},
        'error': '',
        'err': '',
        'result': 0,
      };
    }

    final closeRes = await step('CloseOrder id=$headerId', () {
      return _orderApiInvoke('CloseOrder', {
        'id': headerId,
        'cashbox_id': cashboxIdForOrder,
        'fiscal': fiscalForClose,
      });
    });
    err = _orderApiErrorMessage(closeRes);
    if (err != null) {
      await unlock(headerId);
      return _PhpOrderOutcome.fail(err);
    }
    order = _orderFromApiResponse(closeRes) ?? order;

    await step('UnlockTable id=$headerId', () {
      return _orderApiInvoke('UnlockTable', {
        'locksrc': lockSrc,
        'id': headerId,
        'empty_order': false,
      });
    });

    return _PhpOrderOutcome.ok(
      <String, dynamic>{
        'data': order ?? <String, dynamic>{},
        if (fiscalOutForReceipt != null) 'fiscal_tax': fiscalOutForReceipt,
      },
      usedLocalFiscal: usedLocalFiscal,
    );
  }

  Map<String, dynamic>? _fiscalMapFromOrderPayload(Map<String, dynamic> order) {
    final f = order['fiscal'];
    if (f is Map) return Map<String, dynamic>.from(f);
    if (f is String && f.isNotEmpty) {
      try {
        final d = jsonDecode(f);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return null;
  }

  /// Отправка предчека: POST JSON на URL `print_server` (`command`, `key`, `printer_name`, `print_data` — список `{cmd:…}`).
  Future<void> sendReceiptPrintViaWebSocket({
    required Map<String, dynamic> order,
    Map<String, dynamic>? fiscalTax,
    bool showLoadingDialog = true,
  }) async {
    if (showLoadingDialog) {
      dialogController.add(2);
    }
    try {
      final pname = _receiptPrinterName;
      if (pname == null || pname.isEmpty) {
        if (showLoadingDialog) {
          Navigator.pop(Loading.dialogContext);
        }
        dialogController.add(locale().receiptPrinterNotConfigured);
        return;
      }
      final printUrl = _printServerUrl ?? _trimmedStringConfig(prefs.string('print_server'));
      if (printUrl == null || printUrl.isEmpty) {
        if (showLoadingDialog) {
          Navigator.pop(Loading.dialogContext);
        }
        dialogController.add(locale().printServerNotConfigured);
        return;
      }
      final printData = await buildReceiptPrintCmdList(
        order: order,
        fiscalTax: fiscalTax,
        loc: locale(),
        staffName: osLoginUserName(),
      );
      final printKey =
          _printServerKey ?? _trimmedStringConfig(prefs.string('print_server_key')) ?? '';
      final body = <String, dynamic>{
        'command': 'print',
        'key': printKey,
        'printer_name': pname,
        'print_data': printData,
      };
      final json = await postPrintServerJson(url: printUrl, body: body);
      receiptPrintResponse(json);
    } catch (e) {
      if (showLoadingDialog) {
        Navigator.pop(Loading.dialogContext);
      }
      dialogController.add('${locale().printBillFailed}: $e');
    }
  }

  /// Прямая отправка уже готовых команд печати (например, отчётов `/reports/get-report`).
  Future<void> sendRawPrintCommands({
    required List<dynamic> printData,
    bool showLoadingDialog = true,
  }) async {
    if (showLoadingDialog) {
      dialogController.add(2);
    }
    try {
      final pname = _receiptPrinterName;
      if (pname == null || pname.isEmpty) {
        if (showLoadingDialog) {
          Navigator.pop(Loading.dialogContext);
        }
        dialogController.add(locale().receiptPrinterNotConfigured);
        return;
      }
      final printUrl =
          _printServerUrl ?? _trimmedStringConfig(prefs.string('print_server'));
      if (printUrl == null || printUrl.isEmpty) {
        if (showLoadingDialog) {
          Navigator.pop(Loading.dialogContext);
        }
        dialogController.add(locale().printServerNotConfigured);
        return;
      }
      final printKey =
          _printServerKey ?? _trimmedStringConfig(prefs.string('print_server_key')) ?? '';
      final body = <String, dynamic>{
        'command': 'print',
        'key': printKey,
        'printer_name': pname,
        // Для отчётов в приложении оставляем прежний вид, но в печати
        // уменьшаем команды fontsize на 2 перед драйверным bump.
        'print_data': applyPrintDriverFontBump(
          _applyRawPrintFontDelta(printData, delta: -2),
        ),
      };
      final json = await postPrintServerJson(url: printUrl, body: body);
      receiptPrintResponse(json);
    } catch (e) {
      if (showLoadingDialog) {
        Navigator.pop(Loading.dialogContext);
      }
      dialogController.add('${locale().printBillFailed}: $e');
    }
  }

  List<dynamic> _applyRawPrintFontDelta(
    List<dynamic> printData, {
    required int delta,
  }) {
    if (delta == 0) return List<dynamic>.from(printData);
    final out = <dynamic>[];
    for (final e in printData) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        if ('${m['cmd']}' == 'fontsize') {
          final s = m['size'];
          final n = s is num ? s.toDouble() : double.tryParse('$s') ?? 0;
          final v = (n + delta).round();
          m['size'] = v < 1 ? 1 : v;
        }
        out.add(m);
      } else {
        out.add(e);
      }
    }
    return out;
  }

  void receiptPrintResponse(Map<String, dynamic> json) {
    try {
      Navigator.pop(Loading.dialogContext);
    } catch (_) {}
    final code = json['errorCode'];
    final errCode = code is int
        ? code
        : (code is num ? code.toInt() : int.tryParse('$code'));
    if (errCode != null && errCode != 0) {
      dialogController.add(
          '${locale().printBillFailed} \r\n ${json['errorMessage'] ?? ''}');
    }
  }

  Future<void> _finishCheckoutWithReceiptWs(dynamic bundle) async {
    final m = bundle is Map<String, dynamic>
        ? bundle
        : <String, dynamic>{};
    final od = m['data'];
    final ft = m['fiscal_tax'];
    if (od is Map) {
      await sendReceiptPrintViaWebSocket(
        order: Map<String, dynamic>.from(od),
        fiscalTax: ft is Map<String, dynamic>
            ? Map<String, dynamic>.from(ft)
            : null,
        showLoadingDialog: false,
      );
    }
    Dialogs.show(locale().yourOrderWasCreated).then((value) {
      navHome();
    });
  }

  /// Строка истории смены: только итоги и оплаты (состав заказа в ответе нет).
  Future<void> printHistoryReceiptRow(Map<String, dynamic> row) async {
    final order = <String, dynamic>{
      'f_state': 3,
      'f_hall_name': '${row['f_hallid'] ?? ''}',
      'f_table_name': '',
      'f_receipt_number': '${row['f_id'] ?? ''}',
      'f_amounttotal': row['f_amounttotal'],
      'f_subtotal': row['f_amounttotal'],
      'f_amount_cash': row['f_amountcash'] ?? row['f_amount_cash'],
      'f_amount_card': row['f_amountcard'] ?? row['f_amount_card'],
      'f_amount_idram': row['f_amountidram'] ?? row['f_amount_idram'],
      'f_amount_other': row['f_amountother'] ?? row['f_amount_other'],
      'f_car_number': row['f_govnumber'],
    };
    await sendReceiptPrintViaWebSocket(order: order, fiscalTax: null);
  }

  void startOrder(Map<String, dynamic> o) {
    httpQuery(query_start_order, o, '/engine/carwash/start-order.php');
  }

  void endOrder(Map<String, dynamic> o) {
    ProcessEndScreen.show(o, this).then((value) {
      if (value ?? false) {}
    });
  }

  void httpOk(int code, dynamic data) {
    switch (code) {
      case query_init:
        appdata.part1.clear();
        appdata.part2.clear();
        appdata.dish.clear();
        appdata.tables.clear();
        for (final e in data['part1'] ?? []) {
          if (appdata.part1filter == 0) {
            final v = idVal(e['f_id']);
            if (v != null) {
              appdata.part1filter = v;
            }
          }
          appdata.part1.add(Map<String, dynamic>.from(e as Map));
        }
        for (final e in data['part2'] ?? []) {
          appdata.part2.add(Map<String, dynamic>.from(e as Map));
        }
        for (final e in data['dish'] ?? []) {
          appdata.dish.add(Map<String, dynamic>.from(e as Map));
        }
        for (final e in data['tables'] ?? []) {
          appdata.tables.add(e);
        }
        final p2s = appdata.part2List(appdata.part1filter);
        if (p2s.isNotEmpty && appdata.part2filter == 0) {
          final firstId = idVal(p2s.first['f_id']);
          if (firstId != null && firstId != 0) {
            appdata.filterDishes(firstId);
          }
        }

        break;
      case query_print_fiscal:
        appdata.basket.clear();
        appdata.basketData.clear();
        carNumberController.clear();
        appdata.basketTotal();
        final bundle = data is Map<String, dynamic>
            ? data
            : <String, dynamic>{};
        unawaited(_finishCheckoutWithReceiptWs(bundle));
        break;
      case query_print_bill:
        if (kDebugMode) {
          print('PRINTING BILL');
        }
        break;
      case query_create_order:

        appdata.basket.clear();
        appdata.basketData.clear();
        carNumberController.clear();
        appdata.basketTotal();
        basketController.add(null);

        Map<String,dynamic> dd = {};
        if (data is String) {
          dd.addAll(jsonDecode(data));
        } else {
          dd.addAll(data);
        }
        if (printFiscal) {
          final jsonMsg = <String,dynamic>{};
          jsonMsg['command'] = 'fiscal';
          jsonMsg['handler'] = 'fiscal';
          jsonMsg['debug_fiscal_ok'] = true;
          jsonMsg['key'] = "asdf7fa8kk49888d!!jjdjmskkak98983mj???m";
          jsonMsg['order'] = dd['data'];
          dialogController.add(1);
          appWebsocket.sendMessage(jsonEncode(jsonMsg), printFiscalResponse);
        } else {
          final raw = dd['data'];
          if (raw is Map) {
            unawaited(sendReceiptPrintViaWebSocket(
              order: Map<String, dynamic>.from(raw),
              fiscalTax: null,
            ));
          }
        }
          break;
    }
  }

  void printFiscalResponse(Map<String, dynamic> json){
    Navigator.pop(Loading.dialogContext);
    if (json['errorCode'] != 0) {
      if (json['errorCode'] == -5) {
        json['errorMessage'] = locale().checkConnectionWithFiscalMachine;
      }
      dialogController.add('${locale().printFiscalFailed} \r\n ${json['errorMessage']}');
      return;
    }
    Future.delayed(const Duration(seconds: 1), () {
      final raw = json['order'];
      if (raw is Map) {
        final order = Map<String, dynamic>.from(raw);
        unawaited(sendReceiptPrintViaWebSocket(
          order: order,
          fiscalTax: _fiscalMapFromOrderPayload(order),
        ));
      }
    });

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
    final queryResult = await HttpQuery2(route).request(copy);
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
    if (!printFiscal) {
      appdata.basketData['f_amountcash'] = 0;
      appdata.basketData['f_amountcard'] = 0;
      appdata.basketData['f_amountidram'] = 0;
      appdata.basketData['f_amountother'] = 0;
      appdata.basketData['f_amountcash'] = appdata.basketData['f_amounttotal'];
      basketController.add(null);
    }
  }

  /// Переключение «печатать фискальный чек» без сброса способа оплаты в корзине
  /// (для оплаты из истории и др., где не нужен побочный эффект [changeFiscalMode]).
  void togglePrintFiscalOnly() {
    printFiscal = !printFiscal;
    fiscalController.add(null);
  }
}

class _PhpOrderOutcome {
  final String? error;
  final Map<String, dynamic>? fiscalBundle;
  final bool usedLocalFiscal;

  _PhpOrderOutcome._(this.error, this.fiscalBundle,
      {this.usedLocalFiscal = false});

  factory _PhpOrderOutcome.fail(String message) =>
      _PhpOrderOutcome._(message, null);

  factory _PhpOrderOutcome.ok(Map<String, dynamic> bundle,
          {bool usedLocalFiscal = false}) =>
      _PhpOrderOutcome._(null, bundle, usedLocalFiscal: usedLocalFiscal);
}
