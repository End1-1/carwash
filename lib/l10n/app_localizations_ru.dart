// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get printFiscalFailed => 'Ошибка печати фискального чека';

  @override
  String get fiscalNotConfigured =>
      'Нет данных фискального аппарата (workstation / fiscal_machine)';

  @override
  String get checkConnectionWithFiscalMachine =>
      'Проверьте связь с фискальным аппаратом';

  @override
  String get loading => 'Загрузка';

  @override
  String get printingFiscal => 'Печать фискального чека';

  @override
  String get printingBill => 'Печать счёта';

  @override
  String get printBillFailed => 'Не удалось распечатать счёт';

  @override
  String get printReport => 'Печать отчёта';

  @override
  String get noActiveSession => 'Нет активной смены';

  @override
  String get cashboxNotConfigured =>
      'Касса не настроена (workstation / cashbox_id)';

  @override
  String get openCashSessionBeforeOrder => 'Сначала откройте смену на кассе';

  @override
  String get startNewShift => 'Начать новую смену';

  @override
  String get inProgress => 'В работе';

  @override
  String get pending => 'Ожидание';

  @override
  String get close => 'Закрыть';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get cancel => 'Отмена';

  @override
  String get price => 'Цена';

  @override
  String get connectionSettings => 'Настройки';

  @override
  String get webServer => 'Веб-сервер';

  @override
  String get titleField => 'Заголовок';

  @override
  String get configField => 'Конфиг';

  @override
  String get menuCode => 'Код меню';

  @override
  String get applicationMode => 'Режим приложения';

  @override
  String get showUnpaid => 'Показывать неоплаченные';

  @override
  String get tableField => 'Стол';

  @override
  String get afterBasketNavigateToOrders => 'После корзины — к заказам';

  @override
  String get useSsl => 'Использовать SSL';

  @override
  String get testTimeScale => 'Тестовый масштаб времени';

  @override
  String get testTimeScaleHint =>
      'Если включено, коэффициент делит 60 минут мойки и конец бесплатной парковки через 120 минут после заезда в бокс.';

  @override
  String get testTimeCoefficient => 'Коэффициент тестового времени';

  @override
  String get testTimeScaleSaveFailed =>
      'Не удалось сохранить тестовый масштаб времени';

  @override
  String get amount => 'Сумма';

  @override
  String get cash => 'Наличные';

  @override
  String get card => 'Карта';

  @override
  String get idram => 'Idram';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get report => 'Отчёт';

  @override
  String get startDate => 'Дата начала';

  @override
  String get endDate => 'Дата окончания';

  @override
  String get input => 'Приход';

  @override
  String get amountTotal => 'Итого';

  @override
  String get output => 'Расход';

  @override
  String get salary => 'Зарплата';

  @override
  String get other => 'Прочее';

  @override
  String get paymentNotPaid => 'Не оплачено';

  @override
  String get selfcost => 'Себестоимость';

  @override
  String get profit => 'Прибыль';

  @override
  String get duration => 'Длительность';

  @override
  String get hour => 'ч';

  @override
  String get minutesShort => 'мин';

  @override
  String get add => 'Добавить';

  @override
  String get remove => 'Убрать';

  @override
  String get carNumber => 'Номер авто';

  @override
  String get next => 'Далее';

  @override
  String get printFiscal => 'Печать фискального';

  @override
  String get reprintBill => 'Повторная печать счёта';

  @override
  String get endOrderQuestion => 'Завершить заказ?';

  @override
  String get selectPaymentMethod => 'Выберите способ оплаты';

  @override
  String get finish => 'Готово';

  @override
  String get options => 'Настройки';

  @override
  String get process => 'Процесс';

  @override
  String get cashdesk => 'Заказы по сменам';

  @override
  String get cashReports => 'Отчеты кассы';

  @override
  String get cashRemainsTitle => 'Остатки кассы (30 смен)';

  @override
  String get cashRemainsNoData => 'Нет данных по сменам';

  @override
  String get cashRemainsPreviewTitle => 'Если закрыть смену сейчас';

  @override
  String cashRemainsPreviewHint(Object session) {
    return 'Текущая открытая смена №$session — расчёт на этот момент (как при закрытии).';
  }

  @override
  String get cashRemainsPreviewRemain => 'Остаток в кассе';

  @override
  String get cashRemainsOpenShift => 'открыта';

  @override
  String get cashdeskCloseQuestion => 'Закрыть активную смену кассы?';

  @override
  String get cashMoveMoneyTitle => 'Ввод/вывод средств';

  @override
  String get cashMoveMoneyInput => 'Ввод';

  @override
  String get cashMoveMoneyOutput => 'Вывод';

  @override
  String get cashMoveMoneyAmount => 'Сумма';

  @override
  String get cashMoveMoneyComment => 'Комментарий';

  @override
  String get cashMoveMoneySave => 'Сохранить';

  @override
  String get cashMoveMoneyEnterAmount => 'Введите сумму';

  @override
  String get cashMoveMoneyFailed => 'Ошибка операции по кассе';

  @override
  String get cashMoveMoneyPresetWithdraw => 'изъятие средств';

  @override
  String get history => 'История';

  @override
  String get currentOrders => 'Текущие заказы';

  @override
  String get historyModeReport => 'Отчёт смены';

  @override
  String get historyModeDoneParking => 'Бесплатная / платная парковка';

  @override
  String get historyColRow => 'Стр.';

  @override
  String get historyColCar => 'Авто';

  @override
  String get historyColService => 'Услуга';

  @override
  String get historyColDaily => '№';

  @override
  String get historyColStatus => 'Статус';

  @override
  String get historyColAmount => 'Сумма';

  @override
  String get historyGoodsTotal => 'Итого';

  @override
  String get historyReportColOpened => 'Принят';

  @override
  String historyReportOrdersCount(int count) {
    return 'Заказов: $count';
  }

  @override
  String historyRowsInTable(int count) {
    return 'Строк: $count';
  }

  @override
  String get historyNoReportData => 'Нет данных отчёта';

  @override
  String historyWaitingCars(int count) {
    return 'В ожидании: $count';
  }

  @override
  String get historyStatusDone => 'Выполнено';

  @override
  String get historyStatusWash => 'Мойка';

  @override
  String get historyStatusDry => 'Сушка';

  @override
  String get historyStatusParking => 'Парковка';

  @override
  String get historyStatusFreeParking => 'Бесплатная парковка';

  @override
  String get historyStatusPaidParking => 'Платная парковка';

  @override
  String get historyNoGoodsRows => 'Нет строк «выполнено» или «парковка»';

  @override
  String get historyGoodsFilterAll => 'Все';

  @override
  String get historyGoodsFilterUnpaid => 'Неоплачено';

  @override
  String get historyGoodsFilterNoRows => 'Нет строк по фильтру';

  @override
  String get historyGoodsSearchCarHint => 'Поиск по номеру авто';

  @override
  String get historyGoodsCarSearchNoMatch => 'Нет авто по этому запросу';

  @override
  String get historyPay => 'Оплатить';

  @override
  String get historyPayTitle => 'Оплата';

  @override
  String get historyPayGetOrderFailed => 'Не удалось загрузить заказ с сервера';

  @override
  String get historyPayTotalMismatch =>
      'Суммы оплаты должны совпадать с суммой заказа';

  @override
  String get historyPayMissingOrderId =>
      'В строке нет id заказа (нужны f_header или f_id в шапке)';

  @override
  String get carwashStatus => 'Статус мойки';

  @override
  String get logout => 'Выход';

  @override
  String get order => 'Заказ';

  @override
  String get yourBasketIsEmpty => 'Корзина пуста';

  @override
  String get login => 'Вход';

  @override
  String get date => 'Дата';

  @override
  String get time => 'Время';

  @override
  String get carNumberIncorrect => 'Неверный номер автомобиля';

  @override
  String get yourOrderWasCreated => 'Заказ создан';

  @override
  String get receiptPrinterNotConfigured =>
      'Не задан принтер чека (receipt_printer в конфиге рабочей станции)';

  @override
  String get printServerNotConfigured =>
      'Не задан URL сервера печати (print_server в конфиге рабочей станции)';

  @override
  String get receiptTitle => 'Чек';

  @override
  String get receiptPreorder => 'Предзаказ';

  @override
  String get receiptNameCol => 'Наименование';

  @override
  String get receiptQtyCol => 'Кол-во';

  @override
  String get receiptSubtotal => 'Промежуточно';

  @override
  String get receiptService => 'Обслуживание';

  @override
  String get receiptDiscount => 'Скидка';

  @override
  String get receiptPrepaid => 'Предоплата';

  @override
  String get receiptTotalDue => 'К оплате';

  @override
  String get receiptAmountPaid => 'Внесено';

  @override
  String get receiptChange => 'Сдача';

  @override
  String get receiptThankYou => 'Спасибо за визит!';

  @override
  String get receiptPrinted => 'Напечатано';

  @override
  String get receiptStaff => 'Сотрудник';

  @override
  String get receiptPaymentMethod => 'Оплата';

  @override
  String get receiptPaymentBank => 'Банк';

  @override
  String get receiptPaymentComplimentaryShort => 'Комплимент';

  @override
  String get receiptTin => 'ИНН';

  @override
  String get receiptDeviceNumber => 'Номер устройства';

  @override
  String get receiptSerial => 'Серийный';

  @override
  String get receiptFiscal => 'Фискальный';

  @override
  String get receiptReceiptNumber => 'Номер чека';

  @override
  String get receiptFMarker => '(Ф)';

  @override
  String get receiptClass => 'Класс';

  @override
  String get receiptNoService => '* — без сервиса';

  @override
  String get receiptNoDiscount => '** — без скидки';

  @override
  String get receiptComplimentary => '*** — комплимент';

  @override
  String get receiptSample => 'Образец';

  @override
  String get receiptErrorState => 'Ошибка состояния';

  @override
  String get receiptPrintPluginHint =>
      'Остановите приложение, затем: flutter clean, flutter pub get, flutter run -d windows (полный перезапуск, не hot reload).';

  @override
  String get receiptPrintWindowsOnly =>
      'Печать чека реализована только для Windows.';

  @override
  String get sitePreordersTitle => 'Веб-предзаказы';

  @override
  String get sitePreordersActive => 'Активные';

  @override
  String get sitePreordersHistory => 'История';

  @override
  String get sitePreordersEmpty => 'Нет предзаказов';

  @override
  String get sitePreordersColId => '№';

  @override
  String get sitePreordersColDate => 'Дата';

  @override
  String get sitePreordersColVisit => 'Приезд';

  @override
  String get sitePreordersColCustomer => 'Клиент';

  @override
  String get sitePreordersColPhone => 'Телефон';

  @override
  String get sitePreordersColCar => 'Авто';

  @override
  String get sitePreordersColServices => 'Услуги';

  @override
  String get sitePreordersColTotal => 'Сумма';

  @override
  String get sitePreordersColStatus => 'Статус';

  @override
  String get sitePreordersStatusActive => 'Активный';

  @override
  String get sitePreordersStatusDone => 'Выполнен';

  @override
  String get sitePreordersStatusCancelled => 'Отменён';

  @override
  String get sitePreordersStart => 'Начать';

  @override
  String get sitePreordersStarted => 'Заказ оформлен';

  @override
  String get sitePreordersStartFailed => 'Не удалось оформить заказ';

  @override
  String get sitePreordersStartOnlyActive =>
      'Можно начать только активный предзаказ';

  @override
  String get sitePreordersStartEmptyCart => 'В предзаказе нет услуг';
}
