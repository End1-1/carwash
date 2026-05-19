import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

class Kbd extends StatefulWidget {
  const Kbd({super.key});

  static Future<String?> getText() {
    return showDialog(
      context: prefs.context(),
      builder: (builder) {
      return SimpleDialog(
        contentPadding: const EdgeInsets.all(20),
          children: const [Kbd()],
      );
      },
    );
  }

  @override
  State<Kbd> createState() => _KbdState();
}

class _KbdState extends State<Kbd> {
  static const e0 = '1234567890';
  static const e1 = 'QWERTYUIOP';
  static const e2 = 'ASDFGHJKL';
  static const e3 = 'ZXCVBNM';
  final _te = TextEditingController();

  @override
  void dispose() {
    _te.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _te,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        _buildAlphaRow(e0),
        _buildAlphaRow(e1),
        _buildAlphaRow(e2, extra: [_keyButton('⌫', _backspace)]),
        _buildAlphaRow(e3),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _actionKey('OK', () => Navigator.pop(context, _te.text))),
            const SizedBox(width: 6),
            Expanded(flex: 2, child: _actionKey('Space', _insertSpace)),
            const SizedBox(width: 6),
            Expanded(child: _actionKey('Cancel', () => Navigator.pop(context))),
          ],
        ),
      ],
    );
  }

  Widget _buildAlphaRow(String values, {List<Widget> extra = const []}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < values.length; i++) _keyButton(values[i], () => _pressBtn(values[i])),
          ...extra,
        ],
      ),
    );
  }

  Widget _keyButton(String title, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(3),
      height: 46,
      width: 46,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        border: Border.fromBorderSide(BorderSide(color: Colors.black38)),
      ),
      child: TextButton(onPressed: onPressed, child: Text(title)),
    );
  }

  Widget _actionKey(String title, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(3),
      height: 46,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        border: Border.fromBorderSide(BorderSide(color: Colors.black38)),
      ),
      child: TextButton(onPressed: onPressed, child: Text(title)),
    );
  }

  void _pressBtn(String c) {
    _te.text = '${_te.text}$c';
  }

  void _insertSpace() {
    _te.text = '${_te.text} ';
  }

  void _backspace() {
    if (_te.text.isEmpty) return;
    _te.text = _te.text.substring(0, _te.text.length - 1);
  }
}