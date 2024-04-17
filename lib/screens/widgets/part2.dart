import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:flutter/material.dart';

class Part2 extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppModel model;

  const Part2(this.data, this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          model.appdata.filterDishes(data['f_id']);
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          width: 200,
          height: 200 + 120 ,
          decoration: const BoxDecoration(
              color: Color(0xff004779),
              border: Border.fromBorderSide(
                  BorderSide(color: Colors.white10, width: 2)),
              borderRadius: BorderRadius.all(Radius.circular(4))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            Container(
              clipBehavior:  Clip.hardEdge,
              padding: const EdgeInsets.all(5),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(4))),
                height: 190,
                width: 200,
                child: data['f_image'].isEmpty
                    ? FittedBox(child: Icon(Icons.not_interested_outlined,
                        size: model.screenSize!.width * model.screenMultiple))
                    : FittedBox(child: imageFromBase64(data['f_image'],
                        width: model.screenSize!.width * model.screenMultiple,
                    height: model.screenSize!.width * model.screenMultiple))),
            Expanded(child: Center(child: Text(data['f_name'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18))))
          ]),
        ));
  }
}
