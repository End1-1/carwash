import 'package:carwash/screens/app/model.dart';
import 'package:flutter/material.dart';

abstract class AppScreen extends StatelessWidget {
  final AppModel model;

  const AppScreen( this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: body()),
    );
  }

  PreferredSizeWidget appBar();

  Widget body();
}
