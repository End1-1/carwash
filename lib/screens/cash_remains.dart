import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/l10n/app_localizations.dart';
import 'package:carwash/widgets/app_nav_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashRemainsModel {
  final rows = <List<dynamic>>[];
  final headers = <String>[];

  void clear() {
    rows.clear();
    headers.clear();
  }

  void load(int cashboxId) {
    if (cashboxId <= 0) return;
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryShift(
        '/engine/v2/officen/editors/get-all',
        <String, dynamic>{
          'editor': 'form_cashremains',
          'filter': <Map<String, dynamic>>[
            {'cashbox_id': cashboxId},
          ],
        }));
  }

  void applyResponse(dynamic raw) {
    if (raw is! Map) return;
    final root = Map<String, dynamic>.from(raw);
    final payload = _payload(root);
    final h = payload['headers'];
    if (h is List) {
      headers
        ..clear()
        ..addAll(h.map((e) => '$e'));
    }
    final r = payload['rows'];
    if (r is List) {
      final list = r.whereType<List>().map(List<dynamic>.from).toList();
      list.sort((a, b) {
        final idA = int.tryParse('${a.isNotEmpty ? a[0] : 0}') ?? 0;
        final idB = int.tryParse('${b.isNotEmpty ? b[0] : 0}') ?? 0;
        return idB.compareTo(idA);
      });
      rows
        ..clear()
        ..addAll(list);
    }
  }

  Map<String, dynamic> _payload(Map<String, dynamic> data) {
    final d = data['data'];
    if (d is Map) {
      return Map<String, dynamic>.from(d);
    }
    return data;
  }
}

/// Фиксированные ширины под экран ~1024px (без горизонтального скролла).
class _CashRemainsTableLayout {
  static const double rowNum = 34;
  static const double session = 46;
  static const double date = 66;
  static const double money = 70;
  static const double moneyRemain = 76;

  static List<double> dataColumnWidths(int columnCount) {
    if (columnCount <= 0) return const [];
    final w = <double>[];
    for (var i = 0; i < columnCount; i++) {
      if (i == 0) {
        w.add(session);
      } else if (i == 1 || i == 2) {
        w.add(date);
      } else if (i == columnCount - 1) {
        w.add(moneyRemain);
      } else {
        w.add(money);
      }
    }
    return w;
  }

  static double totalWidth(int dataColumnCount) {
    final cols = dataColumnWidths(dataColumnCount);
    return rowNum + cols.fold(0.0, (a, b) => a + b);
  }
}

class CashRemainsScreen extends AppScreen {
  static final _model = CashRemainsModel();

  CashRemainsScreen(super.model, {super.key}) {
    _reload();
  }

  void _reload() {
    _model.load(model.cashboxIdForOrder);
  }

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
      title: Text(l10n.cashRemainsTitle),
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
      if (model.cashboxIdForOrder <= 0) {
        return Center(child: Text(l10n.cashboxNotConfigured));
      }
      if (_model.rows.isEmpty) {
        return Center(child: Text(l10n.cashRemainsNoData));
      }
      return _table(context, l10n);
    });
  }

  Widget _table(BuildContext context, AppLocalizations l10n) {
    final cols = _model.headers;
    if (cols.isEmpty) {
      return Center(child: Text(l10n.cashRemainsNoData));
    }

    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;
    final headerBg = theme.colorScheme.surfaceContainerHighest;
    final colWidths = _CashRemainsTableLayout.dataColumnWidths(cols.length);
    final tableWidth = _CashRemainsTableLayout.totalWidth(cols.length);

    TextStyle headStyle() => theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.15,
              fontSize: 11,
            ) ??
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.15);

    TextStyle cellStyle({bool bold = false}) =>
        theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.2,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ) ??
        TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w600 : null);

    Widget headerLabel(String text, double width) {
      return SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          child: Text(
            text,
            style: headStyle(),
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 4,
          ),
        ),
      );
    }

    Widget dataCell(
      String text,
      double width, {
      TextAlign align = TextAlign.end,
      bool bold = false,
    }) {
      return SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          child: Text(
            text,
            style: cellStyle(bold: bold),
            textAlign: align,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    TableRow headerRow() {
      return TableRow(
        decoration: BoxDecoration(color: headerBg),
        children: [
          headerLabel(l10n.historyColRow, _CashRemainsTableLayout.rowNum),
          for (var i = 0; i < cols.length; i++)
            headerLabel(cols[i], colWidths[i]),
        ],
      );
    }

    TableRow dataRow(int index, List<dynamic> row) {
      final isLastMoneyCol = cols.length - 1;
      return TableRow(
        children: [
          dataCell(
            '${index + 1}',
            _CashRemainsTableLayout.rowNum,
            align: TextAlign.center,
          ),
          for (var c = 0; c < cols.length; c++)
            dataCell(
              c < row.length ? '${row[c] ?? ''}' : '',
              colWidths[c],
              align: c <= 2 ? TextAlign.center : TextAlign.end,
              bold: c == isLastMoneyCol,
            ),
        ],
      );
    }

    final table = Table(
      border: TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        0: FixedColumnWidth(_CashRemainsTableLayout.rowNum),
        for (var i = 0; i < cols.length; i++)
          i + 1: FixedColumnWidth(colWidths[i]),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        headerRow(),
        for (var i = 0; i < _model.rows.length; i++) dataRow(i, _model.rows[i]),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.clamp(tableWidth, double.infinity);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: w < tableWidth ? tableWidth : tableWidth,
              child: table,
            ),
          ),
        );
      },
    );
  }
}
