import 'package:carwash/utils/prefs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Kbd extends StatelessWidget {

  static Future<String?> getText() {
    return   showDialog(context: prefs.context(), builder: (builder) {
      return SimpleDialog(
        contentPadding: const EdgeInsets.all(20),
        children: [
          Kbd()
        ],
      );
    });
  }

  static const e0 = '1234567890';
  static const e1 = 'QWERTYUIOP';
  static const e2 = 'ASDFGHJKL';
  static const e3 = 'ZXCVBNM';
  final _te = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [Expanded(child: TextFormField(
        controller: _te,
        )),

        ]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < e0.length; i++) ... [
              Container(
                margin: const EdgeInsets.all(5),
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  border: Border.fromBorderSide(BorderSide(color: Colors.black38))
                ),
                child: TextButton(onPressed: (){ _pressBtn(e0[i]);}, child: Text(e0[i])),
              )
            ]
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < e1.length; i++) ... [
              Container(
                margin: const EdgeInsets.all(5),
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.fromBorderSide(BorderSide(color: Colors.black38))
                ),
                child: TextButton(onPressed: (){ _pressBtn(e1[i]);}, child: Text(e1[i])),
              )
            ]
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < e2.length; i++) ... [
              Container(
                margin: const EdgeInsets.all(5),
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.fromBorderSide(BorderSide(color: Colors.black38))
                ),
                child: TextButton(onPressed: (){ _pressBtn(e2[i]);}, child: Text(e2[i])),
              )
            ]
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < e3.length; i++) ... [
              Container(
                margin: const EdgeInsets.all(5),
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.fromBorderSide(BorderSide(color: Colors.black38))
                ),
                child: TextButton(onPressed: (){ _pressBtn(e3[i]);}, child: Text(e3[i])),
              )
            ]
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: (){
              Navigator.pop(context, _te.text);
            }, child: Text('OK')),
            TextButton(onPressed: (){
              Navigator.pop(context);
            }, child: Text('Cancel')),
          ],
        )
      ],
    );
  }

  void _pressBtn(String c) {
    _te.text = _te.text + c;
  }

}