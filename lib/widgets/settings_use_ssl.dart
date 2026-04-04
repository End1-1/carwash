import 'package:carwash/screens/app/model.dart';
import 'package:flutter/material.dart';

class SettingsUseSslDropdown extends StatefulWidget {
  final AppModel model;

  const SettingsUseSslDropdown({super.key, required this.model});

  @override
  State<SettingsUseSslDropdown> createState() => _SettingsUseSslDropdownState();
}

class _SettingsUseSslDropdownState extends State<SettingsUseSslDropdown> {
  static const _border = OutlineInputBorder(
    borderSide: BorderSide(color: Colors.black12),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    return InputDecorator(
      decoration: InputDecoration(
        label: Text(m.locale().useSsl),
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: m.settingsUseSsl,
          items: const [
            DropdownMenuItem(value: 'YES', child: Text('YES')),
            DropdownMenuItem(value: 'NO', child: Text('NO')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => m.settingsUseSsl = v);
          },
        ),
      ),
    );
  }
}
