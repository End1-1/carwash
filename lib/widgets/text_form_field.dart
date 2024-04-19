import 'package:flutter/material.dart';

class MTextFormField extends TextFormField {
  MTextFormField(
      {super.key, required TextEditingController controller,
      int maxLines = 1,
      int minLines = 1,
      bool readOnly = false,
      bool  autofocus = false,
          int? maxLength,
          VoidCallback? onTap,
      required String hintText, super.style})
      : super(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            readOnly: readOnly,
            autofocus: autofocus,
            onTap: onTap,
            maxLength: maxLength,
            decoration: InputDecoration(
                label: Text(hintText),
                border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                    borderRadius: BorderRadius.all(Radius.circular(10)))));
}
