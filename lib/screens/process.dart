import 'dart:async';

import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/screens/process_start.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

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
        title: Text(prefs.appTitle()));
  }

  @override
  Widget body() {
    return _Body(model);
  }
}

class _Body extends StatefulWidget {
  final AppModel model;

  const _Body(this.model);

  @override
  State<StatefulWidget> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late Timer _timer;
  var pending = 0;
  var inProgress = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: widget.model.basketController.stream,
        builder: (builder, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data is int) {
            return const Center(child: CircularProgressIndicator());
          }
          pending = 0;
          inProgress = 0;
          for (final o in snapshot.data) {
            if (o['f_state'] == 1) {
              inProgress++;
            } else {
              pending++;
            }
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.blueAccent, Colors.blue])),
                    child: Text(
                      '${widget.model.tr('In progress')} $inProgress',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  )),
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.deepOrange, Colors.orange])),
                    child: Text(
                      '${widget.model.tr('Pending')} $pending',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ))
                ]),
                //ORDERS
                Expanded(
                    child: SingleChildScrollView(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Expanded(
                          child: Container(
                              color: Colors.blue,
                              child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final o in snapshot.data ?? []) ...[
                                      if (o['f_state'] == 1 || o['f_state'] == 2) ...[
                                        processWidget(o),
                                        const Divider(
                                            color: Colors.white,
                                            height: 2,
                                            thickness: 2)
                                      ]
                                    ],
                                  ]))),
                      Expanded(
                          child: Container(
                              color: Colors.orange,
                              child: Column(children: [
                                for (final o in snapshot.data ?? []) ...[
                                  if (o['f_state'] ==5) ...[
                                    pendingWidget(o),
                                    const Divider(
                                        color: Colors.white,
                                        height: 2,
                                        thickness: 2)
                                  ]
                                ]
                              ]))),
                    ])))
              ]);
        });
  }

  Widget processWidget(Map<String, dynamic> o) {
    return InkWell(
        onTap: () {
          widget.model.endOrder(o);
        },
        child: Container(
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            decoration: BoxDecoration(color: o['f_state'] == 1 ? const Color(0xff94a5ba) : const Color(0xffaaeeaa)),
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
                          Text('${i['f_part2name']} ${i['f_dishname']}',
                              style: const TextStyle(color: Colors.black)),
                          Expanded(child: Container()),
                          const Icon(Icons.access_time_rounded),
                          SizedBox(
                              width: 100,
                              child: Text(
                                  '${processDuration(i['f_begin'], i['f_cookingtime'], widget.model.tr('hour'), widget.model.tr('min'))}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)))
                        ],
                      ),
                      Row(children: [
                        Expanded(child: Container()),
                        const Icon(Icons.access_alarm_rounded),
    SizedBox(
    width: 100,
    child:Text('${dateTimeToTimeStr(o['f_done'])}', textAlign: TextAlign.right,
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
          ProcessStartScreen.show(o, widget.model);
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
                          Text('${i['f_part2name']} ${i['f_dishname']}'),
                          Expanded(child: Container()),
                          const Icon(Icons.access_alarm_rounded),
                          SizedBox(
                              width: 150,
                              child:Text('${dateTimeToTimeStr(o['f_begin'])} - ${dateTimeToTimeStr(o['f_done'])}', textAlign: TextAlign.right,
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
