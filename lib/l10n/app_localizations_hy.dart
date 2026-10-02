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
  String get fiscalNotConfigured =>
      'ՀԴՄ տվյալները բացակայում են (workstation / fiscal_machine)';

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

  @override
  String get printReport => 'Տպել հաշվետվությունը';

  @override
  String get noActiveSession => 'Ակտիվ հերթափոխ չկա';

  @override
  String get cashboxNotConfigured =>
      'Դրամարկղը կարգավորված չէ (workstation / cashbox_id)';

  @override
  String get openCashSessionBeforeOrder => 'Նախ բացեք հերթափոխը';

  @override
  String get startNewShift => 'Սկսել նոր հերթափոխ';

  @override
  String get inProgress => 'Ընթացքում';

  @override
  String get pending => 'Սպասման մեջ';

  @override
  String get close => 'Փակել';

  @override
  String get yes => 'Այո';

  @override
  String get no => 'Ոչ';

  @override
  String get cancel => 'Չեղարկել';

  @override
  String get price => 'Գին';

  @override
  String get connectionSettings => 'Կարգավորում';

  @override
  String get webServer => 'Վեբ սերվեր';

  @override
  String get titleField => 'Վերնագիր';

  @override
  String get configField => 'Կոնֆիգ';

  @override
  String get menuCode => 'Մենյուի կոդ';

  @override
  String get applicationMode => 'Ծրագրի ռեժիմ';

  @override
  String get showUnpaid => 'Ցուցադրել չվճարված';

  @override
  String get tableField => 'Սեղան';

  @override
  String get afterBasketNavigateToOrders => 'Զամբյուղից հետո՝ պատվերներ';

  @override
  String get useSsl => 'Օգտագործել SSL';

  @override
  String get testTimeScale => 'Թեստային ժամանակի մասշտաբ';

  @override
  String get testTimeScaleHint =>
      'Միացված ժամանակ գործակիցը բաժանում է 60 րոպե լվացումը և անվճար պարկինգի ավարտը՝ բոքս մտնելուց 120 րոպե հետո։';

  @override
  String get testTimeCoefficient => 'Թեստային ժամանակի գործակից';

  @override
  String get testTimeScaleSaveFailed =>
      'Չհաջողվեց պահել թեստային ժամանակի մասշտաբը';

  @override
  String get amount => 'Գումար';

  @override
  String get cash => 'Կանխիկ';

  @override
  String get card => 'Քարտ';

  @override
  String get idram => 'Idram';

  @override
  String get notNow => 'Ոչ հիմա';

  @override
  String get report => 'Հաշվետվություն';

  @override
  String get startDate => 'Սկզբի ամսաթիվ';

  @override
  String get endDate => 'Վերջի ամսաթիվ';

  @override
  String get input => 'Մուտք';

  @override
  String get amountTotal => 'Ընդամենը';

  @override
  String get output => 'Ելք';

  @override
  String get salary => 'Աշխատավարձ';

  @override
  String get other => 'Այլ';

  @override
  String get paymentNotPaid => 'Չվճարված';

  @override
  String get selfcost => 'Ինքնարժեք';

  @override
  String get profit => 'Շահույթ';

  @override
  String get duration => 'Տևողություն';

  @override
  String get hour => 'ժ';

  @override
  String get minutesShort => 'ր';

  @override
  String get add => 'Ավելացնել';

  @override
  String get remove => 'Հանել';

  @override
  String get carNumber => 'Պետհամարանիշ';

  @override
  String get next => 'Հաջորդ';

  @override
  String get printFiscal => 'Տպել ՀԴՄ';

  @override
  String get reprintBill => 'Կրկին տպել հաշիվ';

  @override
  String get endOrderQuestion => 'Ավարտել պատվերը՞';

  @override
  String get selectPaymentMethod => 'Ընտրեք վճարման եղանակ';

  @override
  String get finish => 'Ավարտել';

  @override
  String get options => 'Կարգավորումներ';

  @override
  String get process => 'Գործընթաց';

  @override
  String get cashdesk => 'Պատվերներ հերթափոխով';

  @override
  String get cashReports => 'Դրամարկղի հաշվետվություններ';

  @override
  String get cashRemainsTitle => 'Դրամարկղի մնացորդներ (30 հերթափոխ)';

  @override
  String get cashRemainsNoData => 'Հերթափոխերի տվյալներ չկան';

  @override
  String get cashRemainsPreviewTitle => 'Եթե հիմա փակել հերթափոխը';

  @override
  String cashRemainsPreviewHint(Object session) {
    return 'Բաց հերթափոխ №$session — հաշվարկը այս պահի համար (ինչպես փակելիս)։';
  }

  @override
  String get cashRemainsPreviewRemain => 'Դրամարկղի մնացորդ';

  @override
  String get cashRemainsOpenShift => 'բաց';

  @override
  String get cashdeskCloseQuestion => 'Փակե՞լ ակտիվ դրամարկղի հերթափոխը։';

  @override
  String get cashMoveMoneyTitle => 'Դրամի մուտք/ելք';

  @override
  String get cashMoveMoneyInput => 'Մուտք';

  @override
  String get cashMoveMoneyOutput => 'Ելք';

  @override
  String get cashMoveMoneyAmount => 'Գումար';

  @override
  String get cashMoveMoneyComment => 'Մեկնաբանություն';

  @override
  String get cashMoveMoneySave => 'Պահպանել';

  @override
  String get cashMoveMoneyEnterAmount => 'Մուտքագրեք գումարը';

  @override
  String get cashMoveMoneyFailed => 'Դրամարկղի գործողությունը չհաջողվեց';

  @override
  String get cashMoveMoneyPresetWithdraw => 'միջոցների ելք';

  @override
  String get history => 'Պատմություն';

  @override
  String get currentOrders => 'Ընթացիկ պատվերներ';

  @override
  String get historyModeReport => 'Փոխի հաշվետվություն';

  @override
  String get historyModeDoneParking => 'Անվճար / վճարովի պարկինգ';

  @override
  String get historyColRow => 'Տող';

  @override
  String get historyColCar => 'Ավտո';

  @override
  String get historyColService => 'Ծառայություն';

  @override
  String get historyColDaily => 'Համար';

  @override
  String get historyColStatus => 'Կարգավիճակ';

  @override
  String get historyColAmount => 'Գումար';

  @override
  String get historyGoodsTotal => 'Ընդամենը';

  @override
  String get historyReportColOpened => 'Բացված';

  @override
  String historyReportOrdersCount(int count) {
    return 'Պատվերներ՝ $count';
  }

  @override
  String historyRowsInTable(int count) {
    return 'Տողեր՝ $count';
  }

  @override
  String get historyNoReportData => 'Հաշվետվության տվյալներ չկան';

  @override
  String historyWaitingCars(int count) {
    return 'Սպասման մեջ՝ $count';
  }

  @override
  String get historyStatusDone => 'Ավարտված';

  @override
  String get historyStatusWash => 'Լվացում';

  @override
  String get historyStatusDry => 'Չորացում';

  @override
  String get historyStatusParking => 'Կայան';

  @override
  String get historyStatusFreeParking => 'Անվճար պարկինգ';

  @override
  String get historyStatusPaidParking => 'Վճարովի պարկինգ';

  @override
  String get historyNoGoodsRows => 'Չկան «ավարտված» կամ «կայան» տողեր';

  @override
  String get historyGoodsFilterAll => 'Բոլորը';

  @override
  String get historyGoodsFilterUnpaid => 'Չվճարված';

  @override
  String get historyGoodsFilterNoRows => 'Այս զտիչին համապատասխան տողեր չկան';

  @override
  String get historyGoodsSearchCarHint => 'Որոնում ըստ ավտոմոբիլի համարի';

  @override
  String get historyGoodsCarSearchNoMatch =>
      'Այս հարցմանը համապատասխան համարներ չկան';

  @override
  String get historyPay => 'Վճարել';

  @override
  String get historyPayTitle => 'Վճարում';

  @override
  String get historyPayGetOrderFailed => 'Պատվերը սերվերից բեռնել չհաջողվեց';

  @override
  String get historyPayTotalMismatch =>
      'Վճարման գումարները պետք է համընկնեն պատվերի հետ';

  @override
  String get historyPayMissingOrderId =>
      'Պատվերի id-ն բացակայում է (պետք են f_header կամ գլխի f_id)';

  @override
  String get carwashStatus => 'Լվացման կարգավիճակ';

  @override
  String get logout => 'Ելք';

  @override
  String get order => 'Պատվեր';

  @override
  String get yourBasketIsEmpty => 'Զամբյուղը դատարկ է';

  @override
  String get login => 'Մուտք';

  @override
  String get date => 'Ամսաթիվ';

  @override
  String get time => 'Ժամ';

  @override
  String get carNumberIncorrect => 'Պետհամարանիշը սխալ է';

  @override
  String get yourOrderWasCreated => 'Պատվերը ստեղծվեց';

  @override
  String get receiptPrinterNotConfigured =>
      'Չեկի տպիչը կարգավորված չէ (receipt_printer աշխատակայանի կոնֆիգում)';

  @override
  String get printServerNotConfigured =>
      'Տպման սերվերի URL-ը կարգավորված չէ (print_server աշխատակայանի կոնֆիգում)';

  @override
  String get receiptTitle => 'Չեկ';

  @override
  String get receiptPreorder => 'Նախապատվեր';

  @override
  String get receiptNameCol => 'Անվանում';

  @override
  String get receiptQtyCol => 'Քնկ';

  @override
  String get receiptSubtotal => 'Հաշվարկված է';

  @override
  String get receiptService => 'Սպասարկում';

  @override
  String get receiptDiscount => 'Զեղչ';

  @override
  String get receiptPrepaid => 'Նախավճար';

  @override
  String get receiptTotalDue => 'Վճարման են';

  @override
  String get receiptAmountPaid => 'Մուտքագրված';

  @override
  String get receiptChange => 'Մանր';

  @override
  String get receiptThankYou => 'Շնորհակալություն այցելության համար';

  @override
  String get receiptPrinted => 'Տպված';

  @override
  String get receiptStaff => 'Աշխատակից';

  @override
  String get receiptPaymentMethod => 'Վճարում';

  @override
  String get receiptPaymentBank => 'Բանկ';

  @override
  String get receiptPaymentComplimentaryShort => 'Անվճար';

  @override
  String get receiptTin => 'ՀՎՀՀ';

  @override
  String get receiptDeviceNumber => 'ԳՀ';

  @override
  String get receiptSerial => 'ՍՀ';

  @override
  String get receiptFiscal => 'Ֆիսկալ';

  @override
  String get receiptReceiptNumber => 'ԿՀ';

  @override
  String get receiptFMarker => '(Ֆ)';

  @override
  String get receiptClass => 'Դաս';

  @override
  String get receiptNoService => '* — առանց սպասարկման';

  @override
  String get receiptNoDiscount => '** — առանց զեղչի';

  @override
  String get receiptComplimentary => '*** — հյուրասիրություն';

  @override
  String get receiptSample => 'Նմուշ';

  @override
  String get receiptErrorState => 'Վիճակի սխալ';

  @override
  String get receiptPrintPluginHint =>
      'Կանգնեցրեք հավելվածը, ապա՝ flutter clean, flutter pub get, flutter run -d windows (լրիվ վերագործարկում, ոչ թե hot reload):';

  @override
  String get receiptPrintWindowsOnly =>
      'Չեկի տպումը կատարվում է միայն Windows-ում։';

  @override
  String get sitePreordersTitle => 'Վեբ նախապատվերներ';

  @override
  String get sitePreordersActive => 'Ակտիվ';

  @override
  String get sitePreordersHistory => 'Պատմություն';

  @override
  String get sitePreordersEmpty => 'Նախապատվերներ չկան';

  @override
  String get sitePreordersColId => '№';

  @override
  String get sitePreordersColDate => 'Ամսաթիվ';

  @override
  String get sitePreordersColVisit => 'Ժամանում';

  @override
  String get sitePreordersColCustomer => 'Հաճախորդ';

  @override
  String get sitePreordersColPhone => 'Հեռախոս';

  @override
  String get sitePreordersColCar => 'Ավտո';

  @override
  String get sitePreordersColServices => 'Ծառայություններ';

  @override
  String get sitePreordersColTotal => 'Գումար';

  @override
  String get sitePreordersColStatus => 'Կարգավիճակ';

  @override
  String get sitePreordersStatusActive => 'Ակտիվ';

  @override
  String get sitePreordersStatusDone => 'Կատարված';

  @override
  String get sitePreordersStatusCancelled => 'Չեղարկված';

  @override
  String get sitePreordersStart => 'Սկսել';

  @override
  String get sitePreordersStarted => 'Պատվերը ձևակերպված է';

  @override
  String get sitePreordersStartFailed => 'Չհաջողվեց ձևակերպել պատվերը';

  @override
  String get sitePreordersStartOnlyActive =>
      'Կարելի է սկսել միայն ակտիվ նախապատվերը';

  @override
  String get sitePreordersStartEmptyCart =>
      'Նախապատվերում ծառայություններ չկան';
}
