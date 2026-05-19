part of 'cashsession.dart';

extension CashSessionExt on CashSession {
  void startNewSession() {
    final cid = model.cashboxIdForOrder;
    if (cid <= 0) {
      model.dialogController.add(model.locale().cashboxNotConfigured);
      return;
    }
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryOpenSession(
        '/engine/v2/carwash/cashbox/open',
      <String, dynamic>{
        'cashbox_id': cid,
        'amount_open': 0,
      },
    ));
  }
}