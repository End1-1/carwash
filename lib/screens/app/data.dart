import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';

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

  void setItemQty(Map<String, dynamic> data) {
    int index =
        basket.indexWhere((element) => element['f_uuid'] == data['f_uuid']);
    if (index < 0) {
      return;
    }
    basket[index] = data;
    basketTotal();
    model.basketController.add(basket.length);
  }

  void removeBasketItem(Map<String, dynamic> data) {
    int index =
        basket.indexWhere((element) => element['f_uuid'] == data['f_uuid']);
    basket.removeAt(index);
    basketTotal();
    model.basketController.add(basket.length);
  }

  void countWorksStartEnd() {
    final last = <int, DateTime>{1: DateTime.now(), 2: DateTime.now()};

    for (final e in works) {
      if (e['progress'] == 1) {
        continue;
      }
      if (e['progress'] > 1 && e['progress'] < 4) {
        last[e['f_table']] =
            strToDateTime(e['f_washdate']).add(Duration(minutes: e['f_washtime'] + e['f_drytime']));
        e['f_begin'] = strToDateTime(e['f_washdate']);
        e['f_done'] = last[e['f_table']];
      }
    }

    for (final e in works) {
      if (e['progress'] != 1) {
        continue;
      }
      final a = last.keys;
      DateTime lastMin = last[1]!;
      int lastKey = 1;

      for (final i in a) {
        if (lastMin.isAfter(last[i]!)) {
          lastMin = last[i]!;
          lastKey = i;
        }
      }
      e['f_table'] = lastKey;
      e['f_tablename'] = 'BOX $lastKey';
      e['f_begin'] = lastMin;
      e['f_done'] = lastMin.add(Duration(minutes: e['f_washtime'] + e['f_drytime']));
      last[lastKey] = lastMin.add(Duration(minutes: e['f_washtime'] + e['f_drytime']));
    }
  }
}
