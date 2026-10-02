// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get printFiscalFailed => 'Print fiscal failed';

  @override
  String get fiscalNotConfigured =>
      'Fiscal machine not configured (workstation / fiscal_machine)';

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

  @override
  String get printReport => 'Print report';

  @override
  String get noActiveSession => 'No active session';

  @override
  String get cashboxNotConfigured =>
      'Cashbox not configured (workstation / cashbox_id)';

  @override
  String get openCashSessionBeforeOrder =>
      'Open cash session before taking orders';

  @override
  String get startNewShift => 'Start new shift';

  @override
  String get inProgress => 'In progress';

  @override
  String get pending => 'Pending';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancel';

  @override
  String get price => 'Price';

  @override
  String get connectionSettings => 'Settings';

  @override
  String get webServer => 'Web server';

  @override
  String get titleField => 'Title';

  @override
  String get configField => 'Config';

  @override
  String get menuCode => 'Menu code';

  @override
  String get applicationMode => 'Application mode';

  @override
  String get showUnpaid => 'Show unpaid';

  @override
  String get tableField => 'Table';

  @override
  String get afterBasketNavigateToOrders => 'After basket navigate to orders';

  @override
  String get useSsl => 'Use SSL';

  @override
  String get testTimeScale => 'Test time scale';

  @override
  String get testTimeScaleHint =>
      'When on, the coefficient divides the 60-minute wash and the free-parking end at 120 minutes after bay entry.';

  @override
  String get testTimeCoefficient => 'Test time coefficient';

  @override
  String get testTimeScaleSaveFailed => 'Could not save the test time scale';

  @override
  String get amount => 'Amount';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get idram => 'Idram';

  @override
  String get notNow => 'Not now';

  @override
  String get report => 'Report';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get input => 'Input';

  @override
  String get amountTotal => 'Amount total';

  @override
  String get output => 'Output';

  @override
  String get salary => 'Salary';

  @override
  String get other => 'Other';

  @override
  String get paymentNotPaid => 'Not paid';

  @override
  String get selfcost => 'Selfcost';

  @override
  String get profit => 'Profit';

  @override
  String get duration => 'Duration';

  @override
  String get hour => 'hour';

  @override
  String get minutesShort => 'min';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get carNumber => 'Car number';

  @override
  String get next => 'Next';

  @override
  String get printFiscal => 'Print fiscal';

  @override
  String get reprintBill => 'Reprint bill';

  @override
  String get endOrderQuestion => 'End order?';

  @override
  String get selectPaymentMethod => 'Select payment method';

  @override
  String get finish => 'Finish';

  @override
  String get options => 'Options';

  @override
  String get process => 'Process';

  @override
  String get cashdesk => 'Orders by shift';

  @override
  String get cashReports => 'Cash reports';

  @override
  String get cashRemainsTitle => 'Cash remains (last 30 shifts)';

  @override
  String get cashRemainsNoData => 'No shift data';

  @override
  String get cashRemainsPreviewTitle => 'If you close the shift now';

  @override
  String cashRemainsPreviewHint(Object session) {
    return 'Open shift #$session — calculated at this moment (same as on close).';
  }

  @override
  String get cashRemainsPreviewRemain => 'Cash on hand';

  @override
  String get cashRemainsOpenShift => 'open';

  @override
  String get cashdeskCloseQuestion => 'Close active cash session?';

  @override
  String get cashMoveMoneyTitle => 'Cash in/out';

  @override
  String get cashMoveMoneyInput => 'In';

  @override
  String get cashMoveMoneyOutput => 'Out';

  @override
  String get cashMoveMoneyAmount => 'Amount';

  @override
  String get cashMoveMoneyComment => 'Comment';

  @override
  String get cashMoveMoneySave => 'Save';

  @override
  String get cashMoveMoneyEnterAmount => 'Enter amount';

  @override
  String get cashMoveMoneyFailed => 'Cash operation failed';

  @override
  String get cashMoveMoneyPresetWithdraw => 'cash withdrawal';

  @override
  String get history => 'History';

  @override
  String get currentOrders => 'Current orders';

  @override
  String get historyModeReport => 'Session report';

  @override
  String get historyModeDoneParking => 'Free / paid parking';

  @override
  String get historyColRow => '#';

  @override
  String get historyColCar => 'Car';

  @override
  String get historyColService => 'Service';

  @override
  String get historyColDaily => 'No.';

  @override
  String get historyColStatus => 'Status';

  @override
  String get historyColAmount => 'Amount';

  @override
  String get historyGoodsTotal => 'Total';

  @override
  String get historyReportColOpened => 'Opened';

  @override
  String historyReportOrdersCount(int count) {
    return 'Orders: $count';
  }

  @override
  String historyRowsInTable(int count) {
    return 'Rows: $count';
  }

  @override
  String get historyNoReportData => 'No report data';

  @override
  String historyWaitingCars(int count) {
    return 'Waiting: $count';
  }

  @override
  String get historyStatusDone => 'Done';

  @override
  String get historyStatusWash => 'Wash';

  @override
  String get historyStatusDry => 'Drying';

  @override
  String get historyStatusParking => 'Parking';

  @override
  String get historyStatusFreeParking => 'Free parking';

  @override
  String get historyStatusPaidParking => 'Paid parking';

  @override
  String get historyNoGoodsRows => 'No done or parking rows';

  @override
  String get historyGoodsFilterAll => 'All';

  @override
  String get historyGoodsFilterUnpaid => 'Unpaid';

  @override
  String get historyGoodsFilterNoRows => 'No rows match this filter';

  @override
  String get historyGoodsSearchCarHint => 'Search by car number';

  @override
  String get historyGoodsCarSearchNoMatch => 'No cars match this search';

  @override
  String get historyPay => 'Pay';

  @override
  String get historyPayTitle => 'Payment';

  @override
  String get historyPayGetOrderFailed => 'Could not load order from server';

  @override
  String get historyPayTotalMismatch =>
      'Payment amounts must match the order total';

  @override
  String get historyPayMissingOrderId =>
      'Order id missing in server row (need f_header or header f_id)';

  @override
  String get carwashStatus => 'Carwash status';

  @override
  String get logout => 'Logout';

  @override
  String get order => 'Order';

  @override
  String get yourBasketIsEmpty => 'Your basket is empty';

  @override
  String get login => 'Login';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get carNumberIncorrect => 'Car number incorrect';

  @override
  String get yourOrderWasCreated => 'Your order was created';

  @override
  String get receiptPrinterNotConfigured =>
      'Receipt printer not configured (receipt_printer in workstation config)';

  @override
  String get printServerNotConfigured =>
      'Print server URL not configured (print_server in workstation config)';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptPreorder => 'Preorder';

  @override
  String get receiptNameCol => 'Name';

  @override
  String get receiptQtyCol => 'Qty';

  @override
  String get receiptSubtotal => 'Subtotal';

  @override
  String get receiptService => 'Service';

  @override
  String get receiptDiscount => 'Discount';

  @override
  String get receiptPrepaid => 'Prepaid amount';

  @override
  String get receiptTotalDue => 'Total due';

  @override
  String get receiptAmountPaid => 'Amount paid';

  @override
  String get receiptChange => 'Change';

  @override
  String get receiptThankYou => 'Thank you for visit!';

  @override
  String get receiptPrinted => 'Printed';

  @override
  String get receiptStaff => 'Staff';

  @override
  String get receiptPaymentMethod => 'Payment';

  @override
  String get receiptPaymentBank => 'Bank';

  @override
  String get receiptPaymentComplimentaryShort => 'Complimentary';

  @override
  String get receiptTin => 'TIN';

  @override
  String get receiptDeviceNumber => 'Device number';

  @override
  String get receiptSerial => 'Serial';

  @override
  String get receiptFiscal => 'Fiscal';

  @override
  String get receiptReceiptNumber => 'Receipt number';

  @override
  String get receiptFMarker => '(F)';

  @override
  String get receiptClass => 'Class';

  @override
  String get receiptNoService => '* - no service';

  @override
  String get receiptNoDiscount => '** - no discount';

  @override
  String get receiptComplimentary => '*** - complimentary';

  @override
  String get receiptSample => 'Sample';

  @override
  String get receiptErrorState => 'Error in state';

  @override
  String get receiptPrintPluginHint =>
      'Stop the app, then: flutter clean, flutter pub get, flutter run -d windows (full restart, not hot reload).';

  @override
  String get receiptPrintWindowsOnly =>
      'Receipt printing is only implemented on Windows.';

  @override
  String get sitePreordersTitle => 'Web pre-orders';

  @override
  String get sitePreordersActive => 'Active';

  @override
  String get sitePreordersHistory => 'History';

  @override
  String get sitePreordersEmpty => 'No pre-orders';

  @override
  String get sitePreordersColId => 'No.';

  @override
  String get sitePreordersColDate => 'Date';

  @override
  String get sitePreordersColVisit => 'Visit';

  @override
  String get sitePreordersColCustomer => 'Customer';

  @override
  String get sitePreordersColPhone => 'Phone';

  @override
  String get sitePreordersColCar => 'Car';

  @override
  String get sitePreordersColServices => 'Services';

  @override
  String get sitePreordersColTotal => 'Total';

  @override
  String get sitePreordersColStatus => 'Status';

  @override
  String get sitePreordersStatusActive => 'Active';

  @override
  String get sitePreordersStatusDone => 'Done';

  @override
  String get sitePreordersStatusCancelled => 'Cancelled';

  @override
  String get sitePreordersStart => 'Start';

  @override
  String get sitePreordersStarted => 'Order created';

  @override
  String get sitePreordersStartFailed => 'Failed to create order';

  @override
  String get sitePreordersStartOnlyActive =>
      'Only active pre-orders can be started';

  @override
  String get sitePreordersStartEmptyCart => 'Pre-order has no services';
}
