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
  int previewSessionId = 0;
  String previewTodayRemain = '';

  void clear() {
    rows.clear();
    headers.clear();
    previewSessionId = 0;
    previewTodayRemain = '';
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
    previewSessionId = _intVal(payload['preview_session_id']);
    previewTodayRemain = '';

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
        if (idA == previewSessionId) return -1;
        if (idB == previewSessionId) return 1;
        return idB.compareTo(idA);
      });
      rows
        ..clear()
        ..addAll(list);
    }

    final preview = payload['preview'];
    if (preview is Map) {
      final m = Map<String, dynamic>.from(preview);
      final remain = m['f_today_remain'];
      if (remain is num) {
        previewTodayRemain = _formatMoney(remain.toDouble());
      }
    }
    if (previewTodayRemain.isEmpty && previewSessionId > 0) {
      for (final row in rows) {
        if (row.isEmpty) continue;
        if (_intVal(row[0]) == previewSessionId && row.length > 9) {
          previewTodayRemain = '${row[9]}';
          break;
        }
      }
    }
  }

  int _intVal(dynamic v) => int.tryParse('$v') ?? 0;

  String _formatMoney(double v) {
    if (v == v.roundToDouble()) return '${v.round()}';
    return v.toStringAsFixed(2);
  }

  Map<String, dynamic> _payload(Map<String, dynamic> data) {
    final d = data['data'];
    if (d is Map) {
      return Map<String, dynamic>.from(d);
    }
    return data;
  }

  bool isPreviewRow(List<dynamic> row) {
    if (previewSessionId <= 0 || row.isEmpty) return false;
    return _intVal(row[0]) == previewSessionId;
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_model.previewSessionId > 0) _previewBanner(l10n),
          Expanded(child: _table(context, l10n)),
        ],
      );
    });
  }

  Widget _previewBanner(AppLocalizations l10n) {
    final remain = _model.previewTodayRemain;
    return Material(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cashRemainsPreviewTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.cashRemainsPreviewHint(_model.previewSessionId),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
            if (remain.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${l10n.cashRemainsPreviewRemain}: ',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    remain,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _table(BuildContext context, AppLocalizations l10n) {
    final cols = _model.headers;
    if (cols.isEmpty) {
      return Center(child: Text(l10n.cashRemainsNoData));
    }

    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;
    final headerBg = theme.colorScheme.surfaceContainerHighest;
    final previewBg = Colors.amber.shade100.withValues(alpha: 0.55);
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

    String cellText(List<dynamic> row, int c) {
      if (c >= row.length) return '';
      final v = row[c];
      if (c == 2 && '$v'.trim().isEmpty) {
        return l10n.cashRemainsOpenShift;
      }
      return '$v';
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
      final isPreview = _model.isPreviewRow(row);
      final isLastMoneyCol = cols.length - 1;
      return TableRow(
        decoration: isPreview
            ? BoxDecoration(color: previewBg)
            : null,
        children: [
          dataCell(
            '${index + 1}',
            _CashRemainsTableLayout.rowNum,
            align: TextAlign.center,
          ),
          for (var c = 0; c < cols.length; c++)
            dataCell(
              cellText(row, c),
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
