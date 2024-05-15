import 'dart:async';

import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OneProcess extends StatefulWidget {
  final data = <String, dynamic>{};
  late final DateTime dt;
  var noTimer = false;
  final AppModel model;

  OneProcess(Map<String, dynamic> d, this.model, {super.key}) {
    data.addAll(d);
    dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(data['f_washdate']);
    if (dt.isBefore(DateTime.now().add(const Duration(minutes: -5)))) {
      noTimer = true;
    }
  }

  @override
  State<StatefulWidget> createState() => _OneProcess();
}

class _OneProcess extends State<OneProcess> {
  static const c1 = Color(0xffec5fbb);
  static const c2 = Color(0xff94a5ba);
  static const c3 = Color(0xffaaeeaa);

  Timer? timer;
  bool? flash;

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.noTimer) {
      flash = false;
    } else {
      timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        if (widget.dt.isBefore(DateTime.now().add(const Duration(minutes: -5)))) {
          if (flash != null) {
            flash = false;
            setState(() {});
          }
          timer.cancel();
        }
        if (flash == null) {
          return;
        }
        setState(() {
          flash = !(flash!);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = <String, dynamic>{};
    o.addAll(widget.data);
    flash ??= false;
    return InkWell(
        onTap: () {
          if (o["progress"] == 2 || o["progress"] == 3 || o['progress'] == 4) {
            widget.model.changeState(o);
          } else {
            if (o['f_amountcash'] == 0 &&
                o['f_amountcard'] == 0 &&
                o['f_amountidram'] == 0) {
              widget.model.endOrder(o);
            }
          }
        },
        child: Container(
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            decoration: BoxDecoration(
                color: flash!
                    ? c1
                    : o['f_state'] == 1
                        ? c2
                        : c3),
            child: Column(
              children: [
                Row(
                  children: [
                    if (o['progress'] == 2)
                      Image.asset(
                        'assets/icons/shower.png',
                        height: 40,
                      ),
                    if (o['progress'] == 3)
                      Image.asset(
                        'assets/icons/fan.png',
                        height: 40,
                      ),
                    if (o['progress'] == 4) ...[
                      if (DateTime.now()
                              .difference(strToDateTime(o['f_washdate']))
                              .inMinutes <=
                          120)
                        Image.asset('assets/icons/timer.png', height: 40),
                      if (DateTime.now()
                              .difference(strToDateTime(o['f_washdate']))
                              .inMinutes >
                          120)
                        Image.asset('assets/icons/parking.png', height: 40),
                    ],
                    Text(
                      o['f_tablename'],
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 30),
                    ),
                    Expanded(child: Container()),
                    const Icon(Icons.car_repair_outlined),
                    SizedBox(
                        width: 100,
                        child: Text(o['f_carnumber'],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 30)))
                  ],
                ),
                Column(
                  children: [
                    for (final i in o['f_items'] ?? []) ...[
                      Row(
                        children: [
                          if ((o['f_amountcash'] ?? 0) > 0 ||
                              (o['f_amountcard'] ?? 0) > 0 ||
                              (o['f_amountidram'] ?? 0) > 0) ...[
                            Icon(Icons.paid_outlined)
                          ],
                          Expanded(
                              flex: 2,
                              child: Text(
                                  '${i['f_part1name']} ${i['f_dishname']}',
                                  maxLines: 2,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900))),
                          Expanded(child: Container()),
                          const Icon(Icons.access_time_rounded),
                          const SizedBox(width: 100, child: Text("S"))
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: Container()),
                          const Icon(Icons.access_alarm_rounded),
                          SizedBox(
                              width: 100,
                              child: Text(
                                  '${DateTime.now().difference(strToDateTime(o['f_washdate'])).inMinutes}',
                                  textAlign: TextAlign.right,
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
}
