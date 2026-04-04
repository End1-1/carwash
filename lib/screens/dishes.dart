import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/screens/widgets/dish.dart';
import 'package:carwash/utils/global.dart';
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
      actions: const [],
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
                if (idEq(e['f_part'], part2))
                  Dish(e, model)
              ]
            ],
          )),
        ))
      ],
    );
  }

}