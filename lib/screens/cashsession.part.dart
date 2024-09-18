part of 'cashsession.dart';


extension CashSessionExt on CashSession {
 void startNewSession() async {
   BlocProvider.of<AppBloc>(prefs.context())
       .add(AppEventQueryOpenSession('/engine/cash/opensession.php', <String, dynamic>{
   }));
 }
}