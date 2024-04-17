import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/screens/widgets/dish.dart';
import 'package:carwash/screens/widgets/dish_basket.dart';
import 'package:carwash/screens/widgets/part2.dart';
import 'package:carwash/screens/widgets/payment.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'welcome_mobile.part.dart';
part 'welcome_desctop.part.dart';

class WelcomeScreen extends AppScreen {
  final _p1controller = ScrollController();
  final _d1controller = ScrollController();

  WelcomeScreen(super.model, {super.key});

  @override
  PreferredSizeWidget appBar() {
    if (model.screenSize!.width < 500) {
      return appBarMobile();
    } else {
      return appBarDesktop();
    }
  }

  @override
  Widget body() {
    if (model.screenSize!.width < 500) {
      return bodyMobile();
    } else {
      return bodyDesktop();
    }
  }

  @override
  List<Widget> menuWidgets() {
    if (model.screenSize!.width < 500) {
      return menuWidgetsMobile();
    } else {
      return [];
    }
  }
}
