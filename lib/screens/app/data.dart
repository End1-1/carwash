import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/widgets/dialogs.dart';

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
    return total;
  }

  // current works
  final List<dynamic> tables = [];
  final List<dynamic> works = [];

  //translation
  final Map<String, Map<String, dynamic>> translation = {};

  void loadPart2(int id) {
    part1filter = id;
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
    int index = basket.indexWhere((element) => element['f_uuid'] == data['f_uuid']);
    if (index < 0) {
      return;
    }
    basket[index] = data;
    model.basketController.add(basket.length);
  }

  void removeBasketItem(Map<String, dynamic> data) {
    int index = basket.indexWhere((element) => element['f_uuid'] == data['f_uuid']);
    basket.removeAt(index);
    model.basketController.add(basket.length);
  }

  void countWorksStartEnd() {
    final reassingTablesList = <Map<String,dynamic>>[];
    List<DateTime> times = List<DateTime>.filled(tables.length, DateTime.now());
    Map<int, int> tablesTimeMap = {};
    for (int i = 0; i < tables.length; i++) {
      tablesTimeMap[tables[i]['f_id']] = i;
    }
    if (tablesTimeMap.isEmpty) {
      Dialogs.show(model.tr('Hall not configured'));
      return;
    }
    //fill in progress
    for (final e in works) {
      if (e['f_state'] == 1) {
        final i = e['f_items'].first;
        i['f_done'] = strToDateTime(i['f_begin'] ?? '').add(Duration(minutes: i['f_cookingtime']));
        e['f_done'] = i['f_done'];
        times[tablesTimeMap[e['f_table']]!] = i['f_done'];
      }
    }
    //fill pending
    for (int i = 0; i < works.length; i++) {
      final w = works[i];
      if (w['f_items'] == null) {
        continue;
      }
      if (w['f_state'] == 1) {
        continue;
      }
      //find nearest box by time
      var box = -1;
      var boxTime = DateTime.now();
      for (var j = 0 ; j < times.length; j++) {
        if (box < 0) {
          box = j;
          boxTime = times[j];
          continue;
        }
        if (boxTime.isAfter(times[j])) {
          box = j;
          boxTime = times[j];
        }
      }
      //assign work to finded box
      final t = tableOfIndex(box);
      if (w['f_table'] != t['f_id']) {
        reassingTablesList.add({'f_order': w['f_id'], 'f_table' : t['f_id']});
      }
      w['f_table'] = t['f_id'];
      w['f_tablename'] = t['f_name'];
      final wi = w['f_items'].first;
      w['f_begin'] = boxTime;
      w['f_done'] = boxTime.add(Duration(minutes: wi['f_cookingtime']));
      times[box] = times[box].add(Duration(minutes: wi['f_cookingtime']));
    }

    //reassing tables
    if (reassingTablesList.isNotEmpty) {
      model.httpQuery(AppModel.query_reassign_table, {
        'query': AppModel.query_call_function,
        'function': 'sf_reassign_tables',
        'params': <String,dynamic>{
          'list': reassingTablesList
        }
      });
    }
  }
}