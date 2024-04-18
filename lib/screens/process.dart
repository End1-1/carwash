import 'dart:async';

import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

part "process.mobile.dart";
part "process.desktop.dart";

class ProcessScreen extends AppScreen {
  ProcessScreen(super.model, {super.key}) {
    model.getProcessList();
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
        StreamBuilder(stream: model.fiscalController.stream, builder: (builder, snapshot) {
          return Container(padding: const EdgeInsets.all(10), child: InkWell(
            onTap: model.changeFiscalMode,
            child: Image.asset(model.printFiscal ? 'assets/icons/basketball.png' : 'assets/icons/football.png'),
          ));
        }),
        Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Color(0xff004779),
                border: Border.fromBorderSide(BorderSide(color: Colors.white)),
                borderRadius: BorderRadius.all(Radius.circular(50))
            ),
            child: Text(prefs.string('table'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      ],
    );
  }

  @override
  Widget body() {

    return Body(model);
  }
}

class Body extends StatefulWidget {
  final AppModel model;

  const Body(this.model);

  @override
  State<StatefulWidget> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  late Timer _timer;
  var pending = 0;
  var inProgress = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.model.screenSize!.width < 500) {
      return bodyMobile();
    } else {
      return bodyDesktop();
    }

  }

  Widget processWidget(Map<String, dynamic> o) {
    return InkWell(
        onTap: () {
          if (o["progress"] == 2 || o["progress"] == 3) {
             widget.model.changeState(o);
          } else {
            if (o['f_amountcash'] == 0
              && o['f_amountcard'] == 0
            && o['f_amountidram'] == 0) {
              widget.model.endOrder(o);
            }
          }
        },
        child: Container(
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            decoration: BoxDecoration(color: o['f_state'] == 1 ?
            const Color(0xff94a5ba) :
            const Color(0xffaaeeaa)),
            child:
              Column(
              children: [
                Row(
                  children: [
                    if (o['progress'] == 2)
                      Image.asset('assets/icons/shower.png', height: 40,),
                    if (o['progress'] == 3)
                      Image.asset('assets/icons/fan.png', height: 40,),
                    if (o['progress'] == 4)...[
                      if (DateTime.now().difference(strToDateTime(o['f_washdate'])).inMinutes <= 120)
                        Image.asset('assets/icons/timer.png', height: 40),
                      if (DateTime.now().difference(strToDateTime(o['f_washdate'])).inMinutes > 120)
                        Image.asset('assets/icons/parking.png', height: 40),
                    ],

                    Text(
                      o['f_tablename'],
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    Expanded(child: Container()),
                    const Icon(Icons.car_repair_outlined),
                    SizedBox(
                        width: 100,
                        child: Text(o['f_carnumber'],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)))
                  ],
                ),
                Column(
                  children: [
                    for (final i in o['f_items'] ?? []) ...[
                      Row(
                        children: [
                          if ((o['f_amountcash'] ?? 0) > 0
                              || (o['f_amountcard'] ?? 0)> 0
                              || (o['f_amountidram'] ?? 0) > 0) ...[
                            Icon(Icons.paid_outlined)
                          ],
                          Expanded(child: Text('${i['f_part1name']} ${i['f_dishname']}',
                              maxLines: 2,
                              style: const TextStyle(color: Colors.black))),
                          Expanded(child: Container()),
                          const Icon(Icons.access_time_rounded),
                          SizedBox(
                              width: 100,
                              child: Text(
                                  "S"))
                        ],
                      ),
                      Row(children: [
                        Expanded(child: Container()),
                        const Icon(Icons.access_alarm_rounded),
    SizedBox(
    width: 100,
    child:Text('${DateTime.now().difference(strToDateTime(o['f_washdate'])).inMinutes}', textAlign: TextAlign.right,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black)))
                      ],)
                    ]
                  ],
                )
              ],
            )));
  }

  Widget pendingWidget(Map<String, dynamic> o) {
    return InkWell(
        onTap: () {
          if (o["progress"] == 1 ) {
            widget.model.changeState(o);
          } else {
            if (o['f_amountcash'] == 0
                && o['f_amountcard'] == 0
                && o['f_amountidram'] == 0) {
              widget.model.endOrder(o);
            }
          }
        },
        child: Container(
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            decoration: const BoxDecoration(color: Color(0xff94a5ba)),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      o['f_tablename'],
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    Expanded(
                      child: Container(),
                    ),
          const Icon(Icons.car_repair_outlined),
          SizedBox(
            width: 150,
            child: Text(o['f_carnumber'],
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20))),
                  ],
                ),
                Column(
                  children: [
                    for (final i in o['f_items'] ?? []) ...[
                      Row(
                        children: [
                          if ((o['f_amountcash'] ??0) > 0
                          || (o['f_amountcard'] ?? 0) > 0
                          || (o['f_amountidram'] ?? 0) > 0) ...[
                            Icon(Icons.paid_outlined)
                          ],
                          Expanded(child: Text('${i['f_part2name']} ${i['f_dishname']}')),
                          const Icon(Icons.access_alarm_rounded),
                          SizedBox(
                              width: 150,
                              child: Text('${dateTimeToTimeStr(o['f_begin'])} - ${dateTimeToTimeStr(o['f_done'])}', textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)))
                        ],
                      )
                    ]
                  ],
                )
              ],
            )));
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), timerFunction);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void timerFunction(Timer t) {
    widget.model.getProcessList();
  }
}
