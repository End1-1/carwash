// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Armenian (`hy`).
class AppLocalizationsHy extends AppLocalizations {
  AppLocalizationsHy([String locale = 'hy']) : super(locale);

  @override
  String get printFiscalFailed => 'ՀԴՄ չի տպվել';

  @override
  String get checkConnectionWithFiscalMachine => 'Ստուգեք կապը ՀԴՄ սարքի հետ';

  @override
  String get loading => 'Հարցում';

  @override
  String get printingFiscal => 'ՀԴՄ կտրոնի տպում';

  @override
  String get printingBill => 'Հաշվի տպում';

  @override
  String get printBillFailed => 'Հաշիվը չտպվեց';
}
