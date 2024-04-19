import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/preferred_size.dart';

class LoginScreen extends AppScreen {
  const LoginScreen(super.model, {super.key});

  @override
  PreferredSizeWidget appBar() {
    return AppBar(
      centerTitle: true,
      title: Text(model.tr('Login')),
    );
  }

  @override
  Widget body() {
    return Column(children: [
      PinForm(pinOk: model.tryLogin),
      IconButton(onPressed: model.navSettings, icon: Icon(Icons.settings_outlined))
    ]);
  }
}