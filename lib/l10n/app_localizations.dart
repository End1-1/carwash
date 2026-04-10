import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hy.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hy'),
    Locale('ru')
  ];

  /// No description provided for @printFiscalFailed.
  ///
  /// In en, this message translates to:
  /// **'Print fiscal failed'**
  String get printFiscalFailed;

  /// No description provided for @fiscalNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Fiscal machine not configured (workstation / fiscal_machine)'**
  String get fiscalNotConfigured;

  /// No description provided for @checkConnectionWithFiscalMachine.
  ///
  /// In en, this message translates to:
  /// **'Check connection with fiscal machine'**
  String get checkConnectionWithFiscalMachine;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @printingFiscal.
  ///
  /// In en, this message translates to:
  /// **'Printing fiscal'**
  String get printingFiscal;

  /// No description provided for @printingBill.
  ///
  /// In en, this message translates to:
  /// **'Printing bill'**
  String get printingBill;

  /// No description provided for @printBillFailed.
  ///
  /// In en, this message translates to:
  /// **'Print bill failed'**
  String get printBillFailed;

  /// No description provided for @printReport.
  ///
  /// In en, this message translates to:
  /// **'Print report'**
  String get printReport;

  /// No description provided for @noActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get noActiveSession;

  /// No description provided for @cashboxNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cashbox not configured (workstation / cashbox_id)'**
  String get cashboxNotConfigured;

  /// No description provided for @openCashSessionBeforeOrder.
  ///
  /// In en, this message translates to:
  /// **'Open cash session before taking orders'**
  String get openCashSessionBeforeOrder;

  /// No description provided for @startNewShift.
  ///
  /// In en, this message translates to:
  /// **'Start new shift'**
  String get startNewShift;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @connectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get connectionSettings;

  /// No description provided for @webServer.
  ///
  /// In en, this message translates to:
  /// **'Web server'**
  String get webServer;

  /// No description provided for @titleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleField;

  /// No description provided for @configField.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get configField;

  /// No description provided for @menuCode.
  ///
  /// In en, this message translates to:
  /// **'Menu code'**
  String get menuCode;

  /// No description provided for @applicationMode.
  ///
  /// In en, this message translates to:
  /// **'Application mode'**
  String get applicationMode;

  /// No description provided for @showUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Show unpaid'**
  String get showUnpaid;

  /// No description provided for @tableField.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get tableField;

  /// No description provided for @afterBasketNavigateToOrders.
  ///
  /// In en, this message translates to:
  /// **'After basket navigate to orders'**
  String get afterBasketNavigateToOrders;

  /// No description provided for @useSsl.
  ///
  /// In en, this message translates to:
  /// **'Use SSL'**
  String get useSsl;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @idram.
  ///
  /// In en, this message translates to:
  /// **'Idram'**
  String get idram;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @input.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get input;

  /// No description provided for @amountTotal.
  ///
  /// In en, this message translates to:
  /// **'Amount total'**
  String get amountTotal;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @paymentNotPaid.
  ///
  /// In en, this message translates to:
  /// **'Not paid'**
  String get paymentNotPaid;

  /// No description provided for @selfcost.
  ///
  /// In en, this message translates to:
  /// **'Selfcost'**
  String get selfcost;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @carNumber.
  ///
  /// In en, this message translates to:
  /// **'Car number'**
  String get carNumber;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @printFiscal.
  ///
  /// In en, this message translates to:
  /// **'Print fiscal'**
  String get printFiscal;

  /// No description provided for @reprintBill.
  ///
  /// In en, this message translates to:
  /// **'Reprint bill'**
  String get reprintBill;

  /// No description provided for @endOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'End order?'**
  String get endOrderQuestion;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @process.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get process;

  /// No description provided for @cashdesk.
  ///
  /// In en, this message translates to:
  /// **'Cashdesk'**
  String get cashdesk;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @currentOrders.
  ///
  /// In en, this message translates to:
  /// **'Current orders'**
  String get currentOrders;

  /// No description provided for @historyModeReport.
  ///
  /// In en, this message translates to:
  /// **'Session report'**
  String get historyModeReport;

  /// No description provided for @historyModeDoneParking.
  ///
  /// In en, this message translates to:
  /// **'Done / parking'**
  String get historyModeDoneParking;

  /// No description provided for @historyColCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get historyColCar;

  /// No description provided for @historyColService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get historyColService;

  /// No description provided for @historyColDaily.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get historyColDaily;

  /// No description provided for @historyColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get historyColStatus;

  /// No description provided for @historyStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get historyStatusDone;

  /// No description provided for @historyStatusParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get historyStatusParking;

  /// No description provided for @historyNoGoodsRows.
  ///
  /// In en, this message translates to:
  /// **'No done or parking rows'**
  String get historyNoGoodsRows;

  /// No description provided for @historyPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get historyPay;

  /// No description provided for @historyPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get historyPayTitle;

  /// No description provided for @historyPayGetOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load order from server'**
  String get historyPayGetOrderFailed;

  /// No description provided for @historyPayTotalMismatch.
  ///
  /// In en, this message translates to:
  /// **'Payment amounts must match the order total'**
  String get historyPayTotalMismatch;

  /// No description provided for @historyPayMissingOrderId.
  ///
  /// In en, this message translates to:
  /// **'Order id missing in server row (need f_header or header f_id)'**
  String get historyPayMissingOrderId;

  /// No description provided for @carwashStatus.
  ///
  /// In en, this message translates to:
  /// **'Carwash status'**
  String get carwashStatus;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @yourBasketIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your basket is empty'**
  String get yourBasketIsEmpty;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @carNumberIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Car number incorrect'**
  String get carNumberIncorrect;

  /// No description provided for @yourOrderWasCreated.
  ///
  /// In en, this message translates to:
  /// **'Your order was created'**
  String get yourOrderWasCreated;

  /// No description provided for @receiptPrinterNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer not configured (receipt_printer in workstation config)'**
  String get receiptPrinterNotConfigured;

  /// No description provided for @printServerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Print server URL not configured (print_server in workstation config)'**
  String get printServerNotConfigured;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptPreorder.
  ///
  /// In en, this message translates to:
  /// **'Preorder'**
  String get receiptPreorder;

  /// No description provided for @receiptNameCol.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get receiptNameCol;

  /// No description provided for @receiptQtyCol.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get receiptQtyCol;

  /// No description provided for @receiptSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get receiptSubtotal;

  /// No description provided for @receiptService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get receiptService;

  /// No description provided for @receiptDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get receiptDiscount;

  /// No description provided for @receiptPrepaid.
  ///
  /// In en, this message translates to:
  /// **'Prepaid amount'**
  String get receiptPrepaid;

  /// No description provided for @receiptTotalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due'**
  String get receiptTotalDue;

  /// No description provided for @receiptAmountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get receiptAmountPaid;

  /// No description provided for @receiptChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get receiptChange;

  /// No description provided for @receiptThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for visit!'**
  String get receiptThankYou;

  /// No description provided for @receiptPrinted.
  ///
  /// In en, this message translates to:
  /// **'Printed'**
  String get receiptPrinted;

  /// No description provided for @receiptStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get receiptStaff;

  /// No description provided for @receiptPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get receiptPaymentMethod;

  /// No description provided for @receiptPaymentBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get receiptPaymentBank;

  /// No description provided for @receiptPaymentComplimentaryShort.
  ///
  /// In en, this message translates to:
  /// **'Complimentary'**
  String get receiptPaymentComplimentaryShort;

  /// No description provided for @receiptTin.
  ///
  /// In en, this message translates to:
  /// **'TIN'**
  String get receiptTin;

  /// No description provided for @receiptDeviceNumber.
  ///
  /// In en, this message translates to:
  /// **'Device number'**
  String get receiptDeviceNumber;

  /// No description provided for @receiptSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get receiptSerial;

  /// No description provided for @receiptFiscal.
  ///
  /// In en, this message translates to:
  /// **'Fiscal'**
  String get receiptFiscal;

  /// No description provided for @receiptReceiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt number'**
  String get receiptReceiptNumber;

  /// No description provided for @receiptFMarker.
  ///
  /// In en, this message translates to:
  /// **'(F)'**
  String get receiptFMarker;

  /// No description provided for @receiptClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get receiptClass;

  /// No description provided for @receiptNoService.
  ///
  /// In en, this message translates to:
  /// **'* - no service'**
  String get receiptNoService;

  /// No description provided for @receiptNoDiscount.
  ///
  /// In en, this message translates to:
  /// **'** - no discount'**
  String get receiptNoDiscount;

  /// No description provided for @receiptComplimentary.
  ///
  /// In en, this message translates to:
  /// **'*** - complimentary'**
  String get receiptComplimentary;

  /// No description provided for @receiptSample.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get receiptSample;

  /// No description provided for @receiptErrorState.
  ///
  /// In en, this message translates to:
  /// **'Error in state'**
  String get receiptErrorState;

  /// No description provided for @receiptPrintPluginHint.
  ///
  /// In en, this message translates to:
  /// **'Stop the app, then: flutter clean, flutter pub get, flutter run -d windows (full restart, not hot reload).'**
  String get receiptPrintPluginHint;

  /// No description provided for @receiptPrintWindowsOnly.
  ///
  /// In en, this message translates to:
  /// **'Receipt printing is only implemented on Windows.'**
  String get receiptPrintWindowsOnly;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hy', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hy':
      return AppLocalizationsHy();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
