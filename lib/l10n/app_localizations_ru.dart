// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get printFiscalFailed => 'Print fiscal failed';

  @override
  String get checkConnectionWithFiscalMachine =>
      'Check connection with fiscal machine';

  @override
  String get loading => 'Loading';

  @override
  String get printingFiscal => 'Printing fiscal';

  @override
  String get printingBill => 'Printing bill';

  @override
  String get printBillFailed => 'Print bill failed';
}
