import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';

bool _part2HasPartLinks(List<Map<String, dynamic>> part2) =>
    part2.any((p) => p['f_part'] != null);

class Data {
  final AppModel model;

  Data(this.model);

  //menu
  int part1filter = 0;
  int part2filter = 0;
  final List<Map<String, dynamic>> part1 = [];
  final List<Map<String, dynamic>> part2 = [];
  final List<Map<String, dynamic>> dish = [];

  // basket
  final List<Map<String, dynamic>> basket = [];
  final Map<String, dynamic> basketData = {};

  double basketTotal() {
    var total = 0.0;
    for (final i in basket) {
      total += i['f_qty'] * i['f_price'];
    }

    basketData['f_amounttotal'] = total;
    if ((basketData['f_amountcash'] ?? 0 )> 0 && (basketData['f_amountcash'] ?? 0) != basketData['f_amounttotal']) {
      basketData['f_amountcash'] = basketData['f_amounttotal'];
    }
    if ((basketData['f_amountidram'] ?? 0) > 0 && (basketData['f_amountidram'] ?? 0) != basketData['f_amounttotal']) {
      basketData['f_amountidram'] = basketData['f_amounttotal'];
    }
    if ((basketData['f_amountcard'] ?? 0) > 0 && (basketData['f_amountcard'] ?? 0) != basketData['f_amounttotal']) {
      basketData['f_amountcard'] = basketData['f_amounttotal'];
    }
    if ((basketData['f_amountother'] ?? 0) > 0 && (basketData['f_amountother'] ?? 0) != basketData['f_amounttotal']) {
      basketData['f_amountother'] = basketData['f_amounttotal'];
    }
    return total;
  }

  // current works
  final List<dynamic> tables = [];
  /// Боксы сушки (`h_tables` с `f_hall=2`), приходят в `init-data` как `dry`.
  final List<dynamic> dry = [];
  final List<dynamic> works = [];

  void loadPart2(dynamic id) {
    part1filter = idVal(id) ?? 0;
    model.basketController.add(0);
    filterDishes(0);
  }

  void filterDishes(dynamic id) {
    part2filter = idVal(id) ?? 0;
    model.dishesController.add(part2filter);
  }

  List<Map<String, dynamic>> part1List() {
    final l = <Map<String, dynamic>>[];
    for (final p1 in part1) {
      for (final p2 in part2) {
        if (idEq(p2['f_part'], p1['f_id'])) {
          l.add(p1);
          break;
        }
      }
    }
    if (l.isEmpty && part1.isNotEmpty && part2.isNotEmpty) {
      if (!_part2HasPartLinks(part2)) {
        return List<Map<String, dynamic>>.from(part1);
      }
    }
    return l;
  }

  List<Map<String, dynamic>> part2List(int p1) {
    final l = <Map<String, dynamic>>[];
    for (final p2 in part2) {
      if (idEq(p2['f_part'], p1)) {
        l.add(p2);
      }
    }
    if (l.isEmpty && part2.isNotEmpty) {
      if (!_part2HasPartLinks(part2)) {
        return List<Map<String, dynamic>>.from(part2);
      }
    }
    return l;
  }

  Map<String, dynamic> tableOfIndex(int index) {
    return tables[index];
  }

  Map<String, dynamic> dryBoxOfIndex(int index) {
    return dry[index];
  }

  static const int bayCount = 3;
  static const int washOccupyMinutes = 60;

  /// Wash occupancy. Test mode divides the 60 minutes; off stays exactly 60.
  Duration washOccupyDuration() {
    const baseMs = washOccupyMinutes * 60 * 1000;
    if (prefs.string(AppModel.prefKeyBayTestTimeScale) != '1') {
      return const Duration(milliseconds: baseMs);
    }
    final coeff =
        AppModel.normalizedBayTestCoeff(prefs.string(AppModel.prefKeyBayTestTimeCoeff));
    return Duration(milliseconds: (baseMs / coeff).round());
  }

  int get washBoxCount => bayCount;

  int get dryBoxCount => dry.length;

  void setItemQty(Map<String, dynamic> data) {
    if (model.isOrderBusy) {
      return;
    }
    int index =
        basket.indexWhere((element) => element['f_uuid'] == data['f_uuid']);
    if (index < 0) {
      return;
    }
    basket[index] = data;
    basketTotal();
    model.basketController.add(basket.length);
    model.refreshBasketOrderWindowFromServer();
  }

  void removeBasketItem(Map<String, dynamic> data) {
    if (model.isOrderBusy) {
      return;
    }
    int index =
        basket.indexWhere((element) => element['f_uuid'] == data['f_uuid']);
    basket.removeAt(index);
    basketTotal();
    model.basketController.add(basket.length);
    model.refreshBasketOrderWindowFromServer();
  }

  void countWorksStartEnd() {
    final now = DateTime.now();
    final bayFreeAt = <int, DateTime>{
      for (var b = 1; b <= bayCount; b++) b: now,
    };

    for (final e in works) {
      final progress = int.tryParse('${e['progress']}') ?? 0;
      if (progress != 2 && progress != 3) continue;
      final bay = int.tryParse('${e['f_table']}') ?? 0;
      if (bay < 1 || bay > bayCount) continue;
      final begin = strToDateTime(e['f_washdate']);
      final freeAt = begin.add(washOccupyDuration());
      e['f_begin'] = begin;
      e['f_done'] = freeAt;
      if (freeAt.isAfter(bayFreeAt[bay]!)) {
        bayFreeAt[bay] = freeAt;
      }
    }

    for (final e in works) {
      final progress = int.tryParse('${e['progress']}') ?? 0;
      if (progress != 1) continue;
      var bestBay = 1;
      var bestAt = bayFreeAt[1]!;
      for (var b = 2; b <= bayCount; b++) {
        final at = bayFreeAt[b]!;
        if (at.isBefore(bestAt)) {
          bestAt = at;
          bestBay = b;
        }
      }
      if (bestAt.isAfter(now)) {
        e['f_table'] = 0;
        e['f_tablename'] = '';
        continue;
      }
      final start = bestAt.isBefore(now) ? now : bestAt;
      e['f_table'] = bestBay;
      e['f_tablename'] = 'BOX $bestBay';
      e['f_begin'] = start;
      e['f_done'] = start.add(washOccupyDuration());
      bayFreeAt[bestBay] = e['f_done'] as DateTime;
    }
  }
}
