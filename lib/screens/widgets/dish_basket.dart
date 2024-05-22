import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dish_qty.dart';

part 'dish_basket.part.dart';

class DishBasket extends StatelessWidget {
  final _width = 260.0;
  final _heigth = 190.0 + 120.0;
  final AppModel model;
  final Map<String, dynamic> data = {};
  final bool mode;

  DishBasket(Map<String, dynamic> initData, this.model, this.mode, {super.key}) {
    data.addAll(initData);
  }

  @override
  Widget build(BuildContext context) {
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
          Text(data['f_name'],
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
          BlocBuilder<CookingTimeBlok, CookingTimeState>(
              builder: (builder, state) {
            if (data['f_cookingtime'] > 0) {
              return Row(children: [
                IconButton(
                  onPressed: () {
                    data['f_cookingtime'] = data['f_cookingtime'] + 10;
                    BlocProvider.of<CookingTimeBlok>(prefs.context())
                        .add(CookingTimeUpdate());
                  },
                  icon: const Icon(Icons.add_circle_outline_outlined,
                      color: Colors.white),
                ),
                Text(
                  '${model.tr('Duration')}  ${durationToString(data['f_cookingtime'], model.tr('hour'), model.tr('min'))}',
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                    onPressed: () {
                      data['f_cookingtime'] = data['f_cookingtime'] - 10;
                      if (data['f_cookingtime'] < 10) {
                        data['f_cookigtime'] = 10;
                      }
                      BlocProvider.of<CookingTimeBlok>(prefs.context())
                          .add(CookingTimeUpdate());
                    },
                    icon:
                        const Icon(Icons.remove_circle_outline, color: Colors.white)),
              ]);
            }
            return Container();
          }),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text('${model.tr('Price')} ${data['f_price']}֏',
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
                          Navigator.pop(
                              Prefs.navigatorKey.currentContext!, data);
                        },
                        title: model.tr('Add'))
                    : globalOutlinedButton(
                        onPressed: () {
                          model.appdata.removeBasketItem(data);
                        },
                        title: model.tr('Remove')))
          ])
        ]));
  }
}
