import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/screens/widgets/booking.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:flutter/material.dart';

class CarNumberScreen extends AppScreen {
  const CarNumberScreen(super.model, {super.key});

  @override
  PreferredSizeWidget appBar() {
    return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: model.navHome,
        ),
        backgroundColor: Colors.green,
        toolbarHeight: kToolbarHeight,
        title: Text(prefs.appTitle()));
  }

  @override
  Widget body() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: MTextFormField(
                    controller: model.carNumberController,
                    hintText: model.tr('Car number'),
                    maxLength: 8,
                    autofocus: true))
          ],
        ),
        Row(children: [
          Expanded(child: Booking(model))
        ]),
        Expanded(child: Container()),
        Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            height: kButtonHeight,
            alignment: Alignment.center,
            child: globalOutlinedButton(
                onPressed: model.navBasketFromNumber, title: model.tr('Next'))),
        const SizedBox(height: 10),
      ],
    );
  }
}
