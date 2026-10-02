import 'package:carwash/l10n/app_localizations.dart';
import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/app_nav_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SitePreordersModel {
  final active = <Map<String, dynamic>>[];
  final history = <Map<String, dynamic>>[];

  void clear() {
    active.clear();
    history.clear();
  }

  void load() {
    BlocProvider.of<AppBloc>(prefs.context()).add(
      AppEventQueryShift(
        '/engine/v2/carwash/site-preorders/list',
        <String, dynamic>{},
      ),
    );
  }

  void applyResponse(dynamic raw) {
    clear();
    if (raw is! Map) return;
    final root = Map<String, dynamic>.from(raw);
    final data = root['data'];
    final payload = data is Map ? Map<String, dynamic>.from(data) : root;

    final a = payload['active'];
    if (a is List) {
      for (final item in a) {
        if (item is Map) active.add(Map<String, dynamic>.from(item));
      }
    }
    final h = payload['history'];
    if (h is List) {
      for (final item in h) {
        if (item is Map) history.add(Map<String, dynamic>.from(item));
      }
    }
  }
}

class SitePreordersScreen extends AppScreen {
  static final _model = SitePreordersModel();

  SitePreordersScreen(super.model, {super.key}) {
    _model.load();
  }

  void _reload() => _model.load();

  @override
  PreferredSizeWidget appBar() {
    final l10n = model.locale();
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.home_outlined),
        onPressed: model.navHome,
      ),
      backgroundColor: Colors.green,
      toolbarHeight: kToolbarHeight,
      title: Text(l10n.sitePreordersTitle),
      actions: [
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh_outlined),
        ),
        AppNavPopupMenuButton(model: model),
      ],
    );
  }

  @override
  Widget body() {
    final l10n = model.locale();
    return BlocBuilder<AppBloc, AppState>(builder: (context, state) {
      if (state is AppStateShifts) {
        _model.applyResponse(state.data);
      }
      if (_model.active.isEmpty && _model.history.isEmpty) {
        if (state is AppStateLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(child: Text(l10n.sitePreordersEmpty));
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        children: [
          _sectionTitle(l10n.sitePreordersActive),
          _ordersTable(context, l10n, _model.active),
          const SizedBox(height: 16),
          _sectionTitle(l10n.sitePreordersHistory),
          _ordersTable(context, l10n, _model.history),
        ],
      );
    });
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _ordersTable(
    BuildContext context,
    AppLocalizations l10n,
    List<Map<String, dynamic>> orders,
  ) {
    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(l10n.sitePreordersEmpty),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 72,
        columns: [
          DataColumn(label: Text(l10n.sitePreordersColId)),
          DataColumn(label: Text(l10n.sitePreordersColDate)),
          DataColumn(label: Text(l10n.sitePreordersColVisit)),
          DataColumn(label: Text(l10n.sitePreordersColCustomer)),
          DataColumn(label: Text(l10n.sitePreordersColPhone)),
          DataColumn(label: Text(l10n.sitePreordersColCar)),
          DataColumn(label: Text(l10n.sitePreordersColServices)),
          DataColumn(label: Text(l10n.sitePreordersColTotal)),
          DataColumn(label: Text(l10n.sitePreordersColStatus)),
        ],
        rows: orders.map((o) => _dataRow(context, l10n, o)).toList(),
      ),
    );
  }

  DataRow _dataRow(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> order,
  ) {
    return DataRow(
      onSelectChanged: (_) => _showDetails(context, l10n, order),
      cells: [
        DataCell(Text('${order['f_id'] ?? ''}')),
        DataCell(Text(_formatDate(order['f_date']))),
        DataCell(Text(_visitLabel(order))),
        DataCell(Text('${order['customer_name'] ?? ''}')),
        DataCell(Text('${order['customer_phone'] ?? ''}')),
        DataCell(Text(_carLabel(order))),
        DataCell(Text(_cartSummary(order))),
        DataCell(Text(_formatMoney(order['total']))),
        DataCell(Text(_statusLabel(l10n, order['f_status']))),
      ],
    );
  }

  void _showDetails(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> order,
  ) {
    final cart = order['cart'];
    final lines = <String>[];
    if (cart is List) {
      for (final item in cart) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final name = '${m['f_dish_name'] ?? m['f_dish'] ?? ''}'.trim();
        final qty = m['f_qty'] ?? 1;
        final price = m['f_price'] ?? 0;
        lines.add('$name × $qty — $price');
      }
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.sitePreordersColId} #${order['f_id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.sitePreordersColDate}: ${_formatDate(order['f_date'])}'),
              Text('${l10n.sitePreordersColVisit}: ${_visitLabel(order)}'),
              Text('${l10n.sitePreordersColCustomer}: ${order['customer_name'] ?? ''}'),
              Text('${l10n.sitePreordersColPhone}: ${order['customer_phone'] ?? ''}'),
              Text('${l10n.sitePreordersColCar}: ${_carLabel(order)}'),
              Text('${l10n.sitePreordersColStatus}: ${_statusLabel(l10n, order['f_status'])}'),
              const SizedBox(height: 8),
              Text(l10n.sitePreordersColServices, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (lines.isEmpty) Text(l10n.sitePreordersEmpty),
              ...lines.map(Text.new),
              const SizedBox(height: 8),
              Text(
                '${l10n.sitePreordersColTotal}: ${_formatMoney(order['total'])}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        actions: [
          if (int.tryParse('${order['f_status']}') == 1)
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await model.startSitePreorder(order);
                _reload();
              },
              child: Text(l10n.sitePreordersStart),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.finish),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic v) {
    final s = '$v'.trim();
    if (s.length >= 16) return s.substring(0, 16);
    return s;
  }

  String _visitLabel(Map<String, dynamic> order) {
    final dt = order['visit_datetime'];
    if (dt != null && '$dt'.trim().isNotEmpty) {
      return _formatDate(dt);
    }
    final visit = order['visit'];
    if (visit is Map) {
      final m = Map<String, dynamic>.from(visit);
      final combined = '${m['f_datetime'] ?? ''}'.trim();
      if (combined.isNotEmpty) return _formatDate(combined);
      final date = '${m['f_date'] ?? ''}'.trim();
      final time = '${m['f_time'] ?? ''}'.trim();
      if (date.isNotEmpty && time.isNotEmpty) return '$date $time';
    }
    return '—';
  }

  String _formatMoney(dynamic v) {
    final n = double.tryParse('$v') ?? 0;
    if (n == n.roundToDouble()) return '${n.round()}';
    return n.toStringAsFixed(2);
  }

  String _carLabel(Map<String, dynamic> order) {
    final car = order['car'];
    if (car is Map) {
      final m = Map<String, dynamic>.from(car);
      if (m['custom'] == true) {
        final text = '${m['custom_text'] ?? ''}'.trim();
        final type = '${m['type_name'] ?? ''}'.trim();
        if (text.isNotEmpty && type.isNotEmpty) return '$text ($type)';
        if (text.isNotEmpty) return text;
      }
      final brand = m['brand'];
      final model = m['model'];
      if (brand is Map && model is Map) {
        return '${brand['f_name'] ?? ''} ${model['f_name'] ?? ''}'.trim();
      }
    }
    final ct = order['car_type'];
    if (ct is Map) {
      return '${ct['f_name'] ?? ''}'.trim();
    }
    return '—';
  }

  String _cartSummary(Map<String, dynamic> order) {
    final cart = order['cart'];
    if (cart is! List || cart.isEmpty) return '—';
    final parts = <String>[];
    for (final item in cart) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final name = '${m['f_dish_name'] ?? m['f_dish'] ?? ''}'.trim();
      final qty = m['f_qty'] ?? 1;
      if (name.isEmpty) continue;
      parts.add('$name×$qty');
    }
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  String _statusLabel(AppLocalizations l10n, dynamic status) {
    final code = int.tryParse('$status') ?? 0;
    if (code == 1) return l10n.sitePreordersStatusActive;
    if (code == 2) return l10n.sitePreordersStatusDone;
    if (code == 3) return l10n.sitePreordersStatusCancelled;
    return '$status';
  }
}
