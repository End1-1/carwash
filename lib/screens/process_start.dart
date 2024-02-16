import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/http_query.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:flutter/material.dart';

class ProcessStartScreen {
  static List<dynamic> tables = [];

  static Future<bool?> show(Map<String, dynamic> o, AppModel model) async {
    return await showDialog(
        barrierDismissible: false,
        context: Prefs.navigatorKey.currentContext!,
        builder: (builder) {
          return SimpleDialog(
            title: Text(prefs.appTitle()),
            children: [
              FutureBuilder<dynamic>(
                  future: getTableList(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data is String) {
                      return Center(child: Text(snapshot.data));
                    }
                    tables = snapshot.data;
                    if (tables.isNotEmpty) {
                      Map<String, dynamic> t = tables.firstWhere((element) => element['f_id'] == o['f_table'], orElse: () => null);
                      if (t == null) {
                        o['f_tablename'] = tables.first['f_name'];
                        o['f_table'] = tables.first['f_id'];
                      }
                    } else {
                      o['f_table'] = 0;
                    }
                    return _ProcessScreenWidget(o, model);
                  }),
            ],
          );
        });
  }

  static Future<dynamic> getTableList() async {
    final result = await HttpQuery().request({
      'query': -1,
      'function': 'sf_get_free_tables',
      'params': <String, dynamic>{}
    });
    if (result['status'] == 1) {
      return result['data'];
    } else {
      return false;
    }
  }
}

class _ProcessScreenWidget extends StatefulWidget {
  final Map<String, dynamic> o;
  final AppModel model;

  const _ProcessScreenWidget(this.o, this.model);

  @override
  State<StatefulWidget> createState() => _ProcessScreenWidgetState();
}

class _ProcessScreenWidgetState extends State<_ProcessScreenWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          decoration: const BoxDecoration(color: Color(0xff94a5ba)),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                      onTap: () {
                        if (ProcessStartScreen.tables.isEmpty) {
                          return;
                        }
                        selectTable(context);
                      },
                      child: Text(
                        ProcessStartScreen.tables.isEmpty
                            ? widget.model.tr('No free worker')
                            : widget.o['f_tablename'],
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      )),
                  Expanded(
                    child: Container(),
                  ),
                  Text(widget.o['f_carnumber'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ],
              ),
              Column(
                children: [
                  for (final i in widget.o['f_items'] ?? []) ...[
                    Row(
                      children: [
                        Text('${i['f_part2name']} ${i['f_dishname']}')
                      ],
                    )
                  ]
                ],
              )
            ],
          )),
      Row(
        children: [
          Expanded(child: Container()),
          SizedBox(
              width: 100,
              height: kButtonHeight,
              child: globalOutlinedButton(
                  onPressed: () {
                    if (widget.o['f_table'] == 0) {
                      return;
                    }
                    Dialogs
                        .question(widget.model.tr('Start order?'), widget.model)
                        .then((value) {
                      if (value ?? false) {
                        widget.model.startOrder(widget.o);
                        Navigator.pop(context);
                      }
                    });},
                  title: widget.model.tr('Start'))),
          const SizedBox(width: 10),
          SizedBox(
              width: 100,
              height: kButtonHeight,
              child: globalOutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  title: widget.model.tr('Close'))),
          Expanded(child: Container()),
        ],
      )
    ]);
  }

  void selectTable(BuildContext context) {
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (builder) {
          return SimpleDialog(
            children: [
              Container(
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final t in ProcessStartScreen.tables) ...[
                        InkWell(
                            onTap: () {
                              Navigator.pop(context, t);
                            },
                            child: Row(
                              children: [
                                Center(child: Text(t['f_name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)))
                              ],
                            )),
                        const SizedBox(height: 10)
                      ]
                    ],
                  ),
                ),
              )
            ],
          );
        }).then((value) {
      if (value != null) {
        widget.o['f_tablename'] = value['f_name'];
        widget.o['f_table'] = value['f_id'];
        setState(() {});
      }
    });
  }
}
