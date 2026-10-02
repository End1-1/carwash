import 'package:carwash/screens/app/model.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:flutter/material.dart';

class SettingsBayTestTime extends StatefulWidget {
  final AppModel model;

  const SettingsBayTestTime({super.key, required this.model});

  @override
  State<SettingsBayTestTime> createState() => _SettingsBayTestTimeState();
}

class _SettingsBayTestTimeState extends State<SettingsBayTestTime> {
  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(m.locale().testTimeScale),
          subtitle: Text(m.locale().testTimeScaleHint),
          value: m.settingsBayTestTimeScale,
          onChanged: (v) => setState(() => m.settingsBayTestTimeScale = v),
        ),
        MTextFormField(
          controller: m.bayTestTimeCoeffController,
          hintText: m.locale().testTimeCoefficient,
        ),
      ],
    );
  }
}
