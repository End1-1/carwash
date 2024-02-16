import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/screens/widgets/dish_basket.dart';
import 'package:carwash/screens/widgets/payment.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

class BasketScreen extends AppScreen {
  const BasketScreen(super.model, {super.key});

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
      actions: [],
    );
  }

  @override
  Widget body() {
    return StreamBuilder(
        stream: model.basketController.stream,
        builder: (builder, snapshot) {
          if (model.appdata.basket.isEmpty) {
            return Center(child: Text(model.tr('Your basket is empty')));
          }
          model.appdata.basketTotal();
          return Column(
            children: [
              Expanded(
                  child: SingleChildScrollView(
                child: Wrap(runSpacing: 5, children: [
                  const SizedBox(height: 5,),
                  for (final b in model.appdata.basket) ...[
                    DishBasket(b, model, false),
                    const SizedBox(
                      height: 5,
                    )
                  ]
                ]),
              )),
              const SizedBox(
                height: 5,
              ),
              Payment(model.appdata.basketData, model),
              const SizedBox(height: 5,),
              if (model.appdata.basket.isNotEmpty)
                Container(
                    height: kButtonHeight,
                    alignment: Alignment.center,
                    child: globalOutlinedButton(
                        onPressed: model.processOrder,
                        title: model.tr('Order'))),
              const SizedBox(height: 5,),
            ],
          );
        });
  }
}
