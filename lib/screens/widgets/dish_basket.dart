import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'dish_qty.dart';

part 'dish_basket.part.dart';

String _timeWindowText(Map<String, dynamic> data) {
  final s = '${data['f_cooking_start'] ?? ''}'.trim();
  final e = '${data['f_cooking_end'] ?? ''}'.trim();
  if (s.isEmpty || e.isEmpty) return '';
  return '$s - $e';
}

class DishBasket extends StatelessWidget {
  final _width = 260.0;
  final _heigth = 190.0 + 120.0;
  final AppModel model;
  /// В корзине (`mode == false`) — та же ссылка, что в [AppModel.appdata.basket], иначе +/- не попадают в заказ.
  /// В диалоге добавления (`mode == true`) — копия, чтобы не портить строку меню.
  final Map<String, dynamic> data;
  final bool mode;

  DishBasket(Map<String, dynamic> initData, this.model, this.mode, {super.key})
      : data = mode ? Map<String, dynamic>.from(initData) : initData;

  @override
  Widget build(BuildContext context) {
    final locked = model.isOrderBusy;
    return Container(
        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        color: Colors.indigo,
        width: _width,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Container(
                    padding: const EdgeInsets.all(5),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    height: _width * .8,
                    width: _width * .8,
                    child: data['f_image'].isEmpty
                        ? FittedBox(
                            child: Icon(Icons.not_interested_outlined,
                                size: _width))
                        : imageFromBase64(data['f_image'], width: _width)))
          ]),
          Text(data['f_dish_name'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(
            data['f_comment'],
            style: const TextStyle(
                color: Colors.white70, fontStyle: FontStyle.italic),
          ),
          if (data['f_comment'].isNotEmpty)
            const SizedBox(
              height: 10,
            ),
          const SizedBox(
            height: 10,
          ),
          if (_timeWindowText(data).isNotEmpty) ...[
            Text(
              _timeWindowText(data),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Text('${model.locale().price} ${data['f_price']}֏',
                  style: const TextStyle(color: Colors.white)),
              Expanded(child: Container())
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(children: [
            Expanded(
                child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runAlignment: WrapAlignment.center,
                    children: [
                  Container(
                      constraints: BoxConstraints(maxWidth: _width / 2),
                      child: DishQty((q) {
                        if (locked) return;
                        data['f_qty'] = q;
                        model.appdata.setItemQty(data);
                      }, data['f_qty'] ?? 1))
                ])),
            Container(
                constraints: BoxConstraints(maxWidth: _width / 2),
                height: kButtonHeight,
                alignment: Alignment.center,
                child: mode
                    ? globalOutlinedButton(
                        onPressed: () {
                          if (locked) return;
                          Navigator.pop(
                              Prefs.navigatorKey.currentContext!, data);
                        },
                        title: model.locale().add)
                    : globalOutlinedButton(
                        onPressed: () {
                          if (locked) return;
                          model.appdata.removeBasketItem(data);
                        },
                        title: model.locale().remove))
          ])
        ]));
  }
}
