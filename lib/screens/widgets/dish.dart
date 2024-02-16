import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/widgets/dish_dialog.dart';
import 'package:carwash/utils/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Dish extends StatelessWidget {
  final _width = 190.0;
  final _height = 190.0 + 120.0;
  final Map<String, dynamic> data;
  final AppModel model;

  const Dish(this.data, this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: (){
      DishDialog.show(data, model);
    },
    child: Container(
      margin: const EdgeInsets.fromLTRB(5, 10, 5, 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      width: _width,
      height: _height ,
      decoration: const BoxDecoration(
          color: Colors.blueAccent,
          border: Border.fromBorderSide(BorderSide(color: Colors.white10)),
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(5),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                height: _width,
                width: _width,
                child: data['f_image'].isEmpty
                    ? FittedBox(child: Icon(Icons.not_interested_outlined,
                    size: _height))
                    : imageFromBase64(data['f_image'],
                    width: _width)),
        Text(data['f_name'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Expanded(child: Container(),),
        Row(children: [
          Text('${model.tr('Price')} ${data['f_price']}֏', style: const TextStyle(color: Colors.white)), Expanded(child: Container())
        ],)
      ]),
    )
    );
  }

}