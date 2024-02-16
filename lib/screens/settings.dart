import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:flutter/material.dart';


class SettingsScreen extends AppScreen {
  const SettingsScreen(super.model, {super.key});


  @override
  Widget body() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 10),
      Row(children:[
        Expanded(child: MTextFormField(controller: model.settingsServerAddressController, hintText: model.tr('Settings')))
    ]),
      const SizedBox(height: 10),
      Row(children:[
        Expanded(child: MTextFormField(controller: model.titleController, hintText: model.tr('Title')))
      ]),
      const SizedBox(height: 10),
      Row(children:[
        Expanded(child: MTextFormField(controller: model.configController, hintText: model.tr('Config')))
      ]),
      const SizedBox(height: 10),
      Row(children:[
        Expanded(child: MTextFormField(controller: model.menuCodeController, hintText: model.tr('Menu code')))
      ]),
      const SizedBox(height: 10),
      Row(children:[
        Expanded(child: MTextFormField(controller: model.modeController, hintText: model.tr('Application mode')))
      ]),
      const SizedBox(height: 10),
      Row(children:[
        Expanded(child: MTextFormField(controller: model.showUnpaidController, hintText: model.tr('Show unpaid')))
      ]),

      const SizedBox(height: 10),
      Row(children:[
        Expanded(child: MTextFormField(controller: model.tableController, hintText: model.tr('Table')))
      ]),

      const SizedBox(height: 10),
      Row(children:[
        Expanded(child: MTextFormField(controller: model.afterBasketToOrdersController, hintText: model.tr('After basket navigate to orders')))
      ]),
    ],
  );
  }

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
            onPressed: model.saveSettings,
            icon: const Icon(Icons.save_outlined))
      ],
    );
  }

}