import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/settings_use_ssl.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends AppScreen {
  const SettingsScreen(super.model, {super.key});

  @override
  bool get showSlideMenuOverlay => false;

  @override
  Widget body() {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.settingsServerAddressController,
                  hintText: model.locale().connectionSettings),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.settingsWebServerAddressController,
                  hintText: model.locale().webServer),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: SettingsUseSslDropdown(model: model)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.titleController, hintText: model.locale().titleField),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.configController, hintText: model.locale().configField),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.menuCodeController,
                  hintText: model.locale().menuCode),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.modeController,
                  hintText: model.locale().applicationMode),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.showUnpaidController,
                  hintText: model.locale().showUnpaid),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.tableController, hintText: model.locale().tableField),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.orderApiController,
                  hintText:
                      'Order API path (default /engine/v2/waiter/order)'),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MTextFormField(
                  controller: model.afterBasketToOrdersController,
                  hintText:
                      model.locale().afterBasketNavigateToOrders),
          ),
        ]),
      ],
    ));
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
      title: Text('${prefs.appTitle()} ${prefs.string('pkAppVersion')}'),
      actions: [
        IconButton(
            onPressed: model.saveSettings,
            icon: const Icon(Icons.save_outlined))
      ],
    );
  }
}
