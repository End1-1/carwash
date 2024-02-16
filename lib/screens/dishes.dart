import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/screens/widgets/dish.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

class DishesScreen extends AppScreen {
  final int part2;
  const DishesScreen(super.model, this.part2, {super.key});

  @override
  PreferredSizeWidget appBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.home_outlined),
        onPressed: model.navHome,
      ),
      backgroundColor: Colors.green,
      toolbarHeight: kToolbarHeight,
      title: Text(prefs.appTitle()),
      actions: [
        IconButton(
            onPressed: model.navBasket,
            icon: SizedBox(
                width: 24,
                height: 24,
                child: Stack(alignment: Alignment.center, children: [
                  const Icon(Icons.shopping_basket_outlined),
                  StreamBuilder(
                      stream: model.basketController.stream,
                      builder: (builder, snapshot) {
                        if (model.appdata.basket.isEmpty) {
                          return Container();
                        }
                        return Align(
                            alignment: Alignment.topRight,
                            child: Container(
                                width: 16,
                                height: 16,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text('${model.appdata.basket.length}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold))));
                      })
                ])))
      ],
    );
  }

  @override
  Widget body() {
    return Column(
      children: [
        Expanded(child: SingleChildScrollView(
          child: Align(alignment: Alignment.center, child:  Wrap(
            direction: Axis.horizontal,
            children: [
              for (final e in model.appdata.dish) ... [
                if (e['f_part'] == part2)
                  Dish(e, model)
              ]
            ],
          )),
        ))
      ],
    );
  }

}