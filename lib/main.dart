import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/cashdesk.dart';
import 'package:carwash/screens/cashsession.dart';
import 'package:carwash/screens/login.dart';
import 'package:carwash/screens/welcome.dart';
import 'package:carwash/screens/widgets/dish_basket.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/utils/web_query.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(MultiBlocProvider(providers: [
    BlocProvider<AppAnimateBloc>(create: (context) => AppAnimateBloc()),
    BlocProvider<AppBloc>(create: (context) => AppBloc()),
    BlocProvider<CashBloc>(create: (context) => CashBloc()),
    BlocProvider<QuestionBloc>(create: (context) => QuestionBloc()),
    BlocProvider<CookingTimeBlok>(
        create: (context) => CookingTimeBlok(CookingTimeState()))
  ], child: const App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => _App();
}

class _App extends State<App> {
  late final AppModel _appModel;
  var error = '';
  var _isInit = false;

  @override
  void initState() {
    super.initState();
    initialization();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      debugShowCheckedModeBanner: false,
      navigatorKey: Prefs.navigatorKey,
      locale: const Locale('hy'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hy'), Locale('ru')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isInit
          ? _appModel.login
              ? ((prefs.getInt('cashsession') ?? 0) == 0
                  ? CashSession(_appModel)
                  : WelcomeScreen(_appModel..dialogController.add(error)))
              : LoginScreen(_appModel)
          : CircularProgressIndicator(),
    );
  }

  void initialization() async {
    prefs = await SharedPreferences.getInstance();
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      String appName = packageInfo.appName;
      //String packageName = packageInfo.packageName;
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;
      prefs.setString('pkAppName', appName);
      prefs.setString('pkAppVersion', '$version.$buildNumber');
    });
    _appModel = AppModel();
    _appModel.screenSize ??= MediaQuery.sizeOf(context);
    _appModel.configScreenSize();

    if (kIsWeb) {
      prefs.setString("webserveraddress", Uri.base.host);
      await WebHttpQuery('/config/').request({}).then((value) {
        if (value['status'] == 1) {
          prefs.setString("menucode", value["menu_id"].toString());
          prefs.setString("serveraddress", value["serveraddress"]);
        }
      });
    } else {
      if (prefs.string("serveraddress").isEmpty) {
        FlutterNativeSplash.remove();
        return;
      }
    }

    _appModel.initModel().then((value) {
      error = value;
      //FlutterNativeSplash.remove();
      setState(() {});
    });
    _isInit = true;
    FlutterNativeSplash.remove();
  }
}
