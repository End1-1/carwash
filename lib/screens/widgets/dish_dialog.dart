import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/widgets/dish_basket.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

class DishDialog {



  static show(Map<String, dynamic> data, AppModel model) {
    data['f_qty'] = 1.0;
    showGeneralDialog<Map<String, dynamic>?>(
        context: Prefs.navigatorKey.currentContext!,
        barrierDismissible: true,
        barrierLabel: '',
        transitionBuilder: (ctx, a1, a2, child) {
          var curve = Curves.easeInOut.transform(a1.value);
          return Transform.scale(
            scale: curve,
            child: SimpleDialog(
              backgroundColor: Colors.indigo,
              contentPadding: const EdgeInsets.all(10),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              children: [
                DishBasket(data, model, true)
              ],
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, a1, a2) {
          return Container();
        }).then((value) {
      if (value != null) {
        model.addToBasket(value);
      }
    });
  }
}
