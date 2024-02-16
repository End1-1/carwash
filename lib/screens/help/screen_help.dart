import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/preferred_size.dart';

class ScreenHelp extends AppScreen {
  const ScreenHelp(super.model, {super.key});

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
        Row(children:[ Expanded(child: Text('Մեր աշխատակիցը կմոտենա ձեզ', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20),))]),
        const SizedBox(height: 20,),
        Container(
            //padding: EdgeInsets.only(bottom: MediaQuery.of(Prefs.navigatorKey.currentContext!).viewInsets.bottom),
            child: TextFormField(
              controller: model.messageController,
          style: const TextStyle(),
          decoration: const InputDecoration(
            hintText: 'Լրացուցիչ հաղորդագրություն',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black54)
            )
          ),
            minLines: 5,
            maxLines: 20,
        )),
       // Expanded(child: Container()),
        const SizedBox(height: 20,),
        Container(
            //padding: EdgeInsets.only(bottom: MediaQuery.of(Prefs.navigatorKey.currentContext!).viewInsets.bottom),
            height: kButtonHeight,
            alignment: Alignment.center,
            child: globalOutlinedButton(
                onPressed: model.sendMessage,
                title: model.tr('Ուղարկել'))),
      ],
    );
  }
}