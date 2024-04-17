import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';

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
    if (basketData['f_amountcash'] > 0 && basketData['f_amountcash'] != basketData['f_amounttotal']) {
      basketData['f_amountcash'] = basketData['f_amounttotal'];
    }
    if (basketData['f_amountidram'] > 0 && basketData['f_amountidram'] != basketData['f_amounttotal']) {
      basketData['f_amountidram'] = basketData['f_amounttotal'];
    }
    if (basketData['f_amountcard'] > 0 && basketData['f_amountcard'] != basketData['f_amounttotal']) {
      basketData['f_amountcard'] = basketData['f_amounttotal'];
    }
    return total;
  }

  // current works
  final List<dynamic> tables = [];
  final List<dynamic> works = [];

  //translation
  final Map<String, Map<String, dynamic>> translation = {};

  void loadPart2(int id) {
    part1filter = id;
    model.basketController.add(0);
    filterDishes(0);
  }

  void filterDishes(int id) {
    part2filter = id;
    model.dishesController.add(id);
  }

  List<Map<String, dynamic>> part1List() {
    final l = <Map<String, dynamic>>[];
    for (final p1 in part1) {
      for (final p2 in part2) {
        if (p2['f_part'] == p1['f_id']) {
          l.add(p1);
          break;
        }
      }
    }
    return l;
  }

  List<Map<String, dynamic>> part2List(int p1) {
    final l = <Map<String, dynamic>>[];
    for (final p2 in part2) {
      if (p2['f_part'] == p1) {
        l.add(p2);
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
            strToDateTime(e['f_washdate']).add(Duration(minutes: 60));
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
      e['f_done'] = lastMin.add(Duration(minutes: 60));
      last[lastKey] = lastMin.add(Duration(minutes: 60));
    }
  }
}
