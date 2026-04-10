import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/login.dart';
import 'package:carwash/screens/widgets/dish_basket.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carwash/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  prefs = await SharedPreferences.getInstance();
  PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
    String appName = packageInfo.appName;
    //String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    prefs.setString('pkAppName', appName);
    prefs.setString('pkAppVersion', '$version.$buildNumber');
  });
  runApp(MultiBlocProvider(providers: [
    BlocProvider<AppAnimateBloc>(create: (context) => AppAnimateBloc()),
    BlocProvider<AppBloc>(create: (context) => AppBloc()),
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
  final AppModel _appModel = AppModel();
  var error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runInitializationWhenNavigatorReady());
  }

  void _runInitializationWhenNavigatorReady([int attempt = 0]) {
    if (!mounted) return;
    final navContext = Prefs.navigatorKey.currentContext;
    if (navContext == null) {
      if (attempt < 20) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _runInitializationWhenNavigatorReady(attempt + 1));
      }
      return;
    }
    _appModel.screenSize = MediaQuery.sizeOf(navContext);
    _appModel.configScreenSize();
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
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginScreen(_appModel),
    );
  }

  void initialization() async {
    if (!mounted) return;

    prefs.setString(
        'serveraddress', prefs.getString('webserveraddress') ?? '');
    if (prefs.string('serveraddress').isEmpty) {
      FlutterNativeSplash.remove();
      return;
    }

    _appModel.initModel().then((value) {
      if (!mounted) return;
      error = value;
      setState(() {});
    });
    FlutterNativeSplash.remove();
  }
}
