import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/screens/widgets/dish.dart';
import 'package:carwash/screens/widgets/dish_basket.dart';
import 'package:carwash/screens/widgets/part2.dart';
import 'package:carwash/screens/widgets/payment.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'welcome_desctop.part.dart';

class WelcomeScreen extends AppScreen {
  final _p1controller = ScrollController();
  final _d1controller = ScrollController();

  WelcomeScreen(super.model, {super.key});

  @override
  PreferredSizeWidget appBar() {

      return appBarDesktop();

  }

  @override
  Widget body() {
      return bodyDesktop();

  }

  @override
  List<Widget> menuWidgets() {

      return [];

  }
}
