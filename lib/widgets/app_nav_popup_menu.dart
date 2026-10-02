import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Кнопка меню (как на экране заказа): настройки, касса, отчёты, история и т.д.
class AppNavPopupMenuButton extends StatelessWidget {
  final AppModel model;

  const AppNavPopupMenuButton({required this.model, super.key});

  void _beforeNav() {
    BlocProvider.of<AppAnimateBloc>(prefs.context()).add(AppAnimateEvent());
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      icon: const Icon(Icons.settings_outlined),
      itemBuilder: (BuildContext context) => _items(context),
    );
  }

  List<PopupMenuEntry<void>> _items(BuildContext context) {
    final l10n = model.locale();
    return [
      PopupMenuItem<void>(
        child: ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(l10n.options),
          onTap: () {
            Navigator.pop(context);
            _beforeNav();
            model.navSettings();
          },
        ),
      ),
      PopupMenuItem<void>(
        child: ListTile(
          leading: const Icon(Icons.monitor),
          title: Text(l10n.cashdesk),
          onTap: () {
            Navigator.pop(context);
            _beforeNav();
            model.navCashdesk();
          },
        ),
      ),
      PopupMenuItem<void>(
        child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(l10n.cashReports),
          onTap: () {
            Navigator.pop(context);
            _beforeNav();
            model.navCashReports();
          },
        ),
      ),
      PopupMenuItem<void>(
        child: ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: Text(l10n.cashRemainsTitle),
          onTap: () {
            Navigator.pop(context);
            _beforeNav();
            model.navCashRemains();
          },
        ),
      ),
      PopupMenuItem<void>(
        child: ListTile(
          leading: const Icon(Icons.language_outlined),
          title: Text(l10n.sitePreordersTitle),
          onTap: () {
            Navigator.pop(context);
            _beforeNav();
            model.navSitePreorders();
          },
        ),
      ),
      PopupMenuItem<void>(
        child: ListTile(
          leading: const Icon(Icons.history_outlined),
          title: Text(l10n.history),
          onTap: () {
            Navigator.pop(context);
            _beforeNav();
            model.navHistory();
          },
        ),
      ),
      PopupMenuItem<void>(
        child: ListTile(
          leading: const Icon(Icons.playlist_play_outlined),
          title: Text(l10n.currentOrders),
          onTap: () {
            Navigator.pop(context);
            _beforeNav();
            model.navHistoryGoodsProcess();
          },
        ),
      ),
      if ((prefs.getInt('user_group') ?? 0) == 1)
        PopupMenuItem<void>(
          child: ListTile(
            leading: const Icon(Icons.request_page_outlined),
            title: Text(l10n.carwashStatus),
            onTap: () {
              Navigator.pop(context);
              _beforeNav();
              model.navStatus();
            },
          ),
        ),
      PopupMenuItem<void>(
        child: ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.logout),
          onTap: () {
            Navigator.pop(context);
            _beforeNav();
            prefs.setString('passhash', '');
            model.navLogin();
          },
        ),
      ),
    ];
  }
}
