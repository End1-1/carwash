import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/process_end.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';

class ProcessStates {
  static Future<bool?> show(Map<String, dynamic> o, AppModel model) async {
    return await showDialog(
        context: Prefs.navigatorKey.currentContext!,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(10),
            children: [
              _ProcessScreenWidget(o, model),
            ],
          );
        });
  }
}

class _ProcessScreenWidget extends StatefulWidget {
  final Map<String, dynamic> o;
  final AppModel model;
  bool readonly = false;

  _ProcessScreenWidget(this.o, this.model) {
    readonly = (o['f_amountcash'] ?? 0) > 0 ||
        (o['f_amountcard'] ?? 0) > 0 ||
        (o['f_amountidram'] ?? 0) > 0;
  }

  @override
  State<StatefulWidget> createState() => _ProcessScreenWidgetState();
}

class _ProcessScreenWidgetState extends State<_ProcessScreenWidget> {
  @override
  Widget build(BuildContext context) {
    final wait = widget.o['progress'] == 2;
    final wash = widget.o['progress'] == 1 || widget.o['progress'] == 3;
    final dry = widget.o['progress'] < 4;
    final parking = widget.o['progress'] < 4;
    final cancel = widget.o['progress'] < 3;
    final payment = (widget.o['f_amountcash'] ?? 0) == 0 &&
        (widget.o['f_amountcard'] ?? 0) == 0 &&
        (widget.o['f_amountidram'] ?? 0) == 0;
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          //decoration: const BoxDecoration(color: Color(0xff94a5ba)),
          child: Column(children: [
            if (wait) ...[
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.model.changeStateOfProcess(
                              {'newstatus': 1}..addAll(widget.o));
                        },
                        icon: Icon(Icons.av_timer),
                        label: Text('Սապսել')))
              ])
            ],
            if (wash) ...[
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.model.changeStateOfProcess(
                              {'newstatus': 2}..addAll(widget.o));
                        },
                        icon: Icon(Icons.wash_outlined),
                        label: Text('Լվացում')))
              ])
            ],
            if (dry) ...[
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.model.changeStateOfProcess(
                              {'newstatus': 3}..addAll(widget.o));
                        },
                        icon: Icon(Icons.dry_outlined),
                        label: Text('Չորացում')))
              ])
            ],
            if (parking) ...[
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.model.changeStateOfProcess(
                              {'newstatus': 4}..addAll(widget.o));
                        },
                        icon: Icon(Icons.local_parking_outlined),
                        label: Text('Պարկինգ')))
              ])
            ],
            if (payment) ...[
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ProcessEndScreen.show(widget.o, widget.model);
                        },
                        icon: Icon(Icons.payments_outlined),
                        label: Text('Վճարում')))
              ])
            ],
            if (cancel) ...[
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.model.removeOrder(widget.o);
                        },
                        icon: Icon(Icons.cancel_outlined),
                        label: Text('Հեռացնել')))
              ])
            ],
            const SizedBox(height: 5),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close_sharp),
                      label: Text('Փակել')))
            ]),
            const SizedBox(height: 5),
          ]))
    ]);
  }
}
