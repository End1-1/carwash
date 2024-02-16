import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

class Dialogs {
  static Future<void> show(String text) async {
    return await showDialog(
        barrierDismissible: false,
        useSafeArea: true,
        context: Prefs.navigatorKey.currentContext!,
        builder: (context) {
          return AlertDialog(
            title: Text(prefs.appTitle()),
            contentPadding: const EdgeInsets.fromLTRB(30, 5, 30, 5),
            content: Container(
                height: 300,
                alignment: Alignment.center,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 10,
                  style: const TextStyle(fontSize: 18),
                )),
            actions: [
              Center(
                  child: SizedBox.fromSize(
                      size: const Size(150, kButtonHeight),
                      child: globalOutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          title: 'OK')))
            ],
          );
        });
  }

  static Future<bool?> question(String text, AppModel model) async {
    return await showDialog(
        barrierDismissible: false,
        useSafeArea: true,
        context: Prefs.navigatorKey.currentContext!,
        builder: (context) {
          return AlertDialog(
            title: Text(prefs.appTitle()),
            contentPadding: const EdgeInsets.fromLTRB(30, 5, 30, 5),
            content: Container(
                height: 300,
                alignment: Alignment.center,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 10,
                  style: const TextStyle(fontSize: 18),
                )),
            actions: [
             SizedBox.fromSize(
                      size: const Size(100, kButtonHeight),
                      child: globalOutlinedButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          title: model.tr('Yes'))),
               SizedBox.fromSize(
                      size: const Size(100, kButtonHeight),
                      child: globalOutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          title: model.tr('No')))
            ],
          );
        });
  }

  static Future<String?> getPin() async {
    return await showDialog(
        barrierDismissible: true,
        useSafeArea: true,
        context: Prefs.navigatorKey.currentContext!,
        builder: (context) {
          return SimpleDialog(
            alignment: Alignment.center,
            title: Text(prefs.appTitle()),
            children: const [PinForm()],
          );
        });
  }
}

class PinForm extends StatefulWidget {
  const PinForm({super.key});

  @override
  State<StatefulWidget> createState() => _PinFormState();
}

class _PinFormState extends State<PinForm> {
  var pin = '';

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.center,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Container()),
              Container(
                margin: const EdgeInsets.all(5),
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                    color: pin.isNotEmpty ? Colors.black54 : Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Colors.black54))),
              ),
              Container(
                margin: const EdgeInsets.all(5),
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                    color: pin.length >= 2 ? Colors.black54 : Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Colors.black54))),
              ),
              Container(
                margin: const EdgeInsets.all(5),
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                    color: pin.length >= 3 ? Colors.black54 : Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Colors.black54))),
              ),
              Container(
                margin: const EdgeInsets.all(5),
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                    color: pin.length >= 4 ? Colors.black54 : Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Colors.black54))),
              ),
              Expanded(child: Container())
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Container()),
              inkWell('1'),
              inkWell('2'),
              inkWell('3'),
              Expanded(child: Container()),
            ],
          ),
          Row(
            children: [
              Expanded(child: Container()),
              inkWell('4'),
              inkWell('5'),
              inkWell('6'),
              Expanded(child: Container()),
            ],
          ),
          Row(
            children: [
              Expanded(child: Container()),
              inkWell('7'),
              inkWell('8'),
              inkWell('9'),
              Expanded(child: Container()),
            ],
          ),
          Row(
            children: [
              Expanded(child: Container()),
              InkWell(
                  onTap: () {
                    if (pin.isNotEmpty) {
                      pin = pin.substring(0, pin.length - 1);
                      setState(() {});
                    }
                  },
                  child: Container(
                      margin: const EdgeInsets.all(5),
                      alignment: Alignment.center,
                      width: kButtonHeight,
                      height: kButtonHeight,
                      decoration: const BoxDecoration(
                          border: Border.fromBorderSide(
                              BorderSide(color: Colors.black26)),
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      child: const Icon(Icons.backspace))),
              inkWell('0'),
              InkWell(
                  onTap: () {
                    Navigator.pop(context, pin);
                  },
                  child: Container(
                      margin: const EdgeInsets.all(5),
                      alignment: Alignment.center,
                      width: kButtonHeight,
                      height: kButtonHeight,
                      decoration: const BoxDecoration(
                          border: Border.fromBorderSide(
                              BorderSide(color: Colors.black26)),
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      child: const Text('OK'))),
              Expanded(child: Container()),
            ],
          )
        ]));
  }

  Widget btnContainer(String text) {
    return Container(
        margin: const EdgeInsets.all(5),
        alignment: Alignment.center,
        width: kButtonHeight,
        height: kButtonHeight,
        decoration: const BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: Colors.black26)),
            borderRadius: BorderRadius.all(Radius.circular(5))),
        child: Text(text));
  }

  Widget inkWell(String text) {
    return InkWell(
        onTap: () {
          if (pin.length < 5) {
            pin += text;
            setState(() {});
          }
        },
        child: btnContainer(text));
  }
}
