import 'package:carwash/screens/widgets/payment.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/http_query.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:flutter/material.dart';

import 'app/model.dart';

class ProcessEndScreen {
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
        }).then((value) async {
      if (value ?? false) {
        if (o['f_state'] == 1 || o['f_state'] == 5) {
          await model.httpQuery(
              AppModel.query_end_order,
              {
                'f_amountcash': o['f_amountcash'],
                'f_amountcard': o['f_amountcard'],
                'f_amountidram': o['f_amountidram'],
                'f_id': o['f_id']
              },
              'engine/carwash/end-order.php');
          if ((o['f_print'] ?? 0) == 0) {
            await model.httpQuery2(AppModel.query_print_fiscal,
                {"id": o['f_id'], 'mode': model.printFiscal ? 1 : 0},
                route: HttpQuery2.printfiscal);
            // await model.httpQuery(AppModel.query_payment, {
            //   'query': AppModel.query_payment,
            //   'params': o
            // });
          }
        } else {
          o.forEach((key, value) {
            if (value is DateTime) {
              o[key] = dateTimeToStr(value);
            }
          });
          await model.httpQuery(
              AppModel.query_end_order,
              {
                'f_amountcash': o['f_amountcash'],
                'f_amountcard': o['f_amountcard'],
                'f_amountidram': o['f_amountidram'],
                'f_id': o['f_id']
              },
              'engine/carwash/end-order.php');
          if ((o['f_print'] ?? 0) == 0) {
            await model.httpQuery2(AppModel.query_print_fiscal,
                {"id": o['f_id'], 'mode': model.printFiscal ? 1 : 0},
                route: HttpQuery2.printfiscal);
            // await model.httpQuery(AppModel.query_payment, {
            //   'query': AppModel.query_payment,
            //   'params': o
            // });
          }
        }
        return true;
      } else {
        model.getProcessList();
      }
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
  final durationController = TextEditingController();
  final moneyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    durationController.text = '${widget.o['f_items'].first['f_cookingtime']}';
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          decoration: const BoxDecoration(color: Color(0xff94a5ba)),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    widget.o['f_tablename'],
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
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
                    ),
                    // Row(
                    //   children: [
                    //     Text(widget.model.tr('End time')),
                    //     Expanded(child: Container()),
                    //     Text(dateTimeToTimeStr(widget.o['f_done']))
                    //   ],
                    // ),
                    const SizedBox(height: 10),
                    if (widget.o['f_state'] == 1)
                      Row(
                        children: [
                          Expanded(
                              child: MTextFormField(
                            controller: durationController,
                            hintText: widget.model.tr('Duration'),
                          )),
                          IconButton(
                              onPressed: () {
                                widget.o['duration'] = durationController.text;
                                //widget.model.updateDuration(widget.o);
                              },
                              icon: const Icon(Icons.save_outlined))
                        ],
                      )
                  ]
                ],
              )
            ],
          )),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: Payment(
          widget.o,
          widget.model,
          readyonly: widget.readonly,
        )),
      ]),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: Container()),
          SizedBox(
              width: 100,
              height: kButtonHeight,
              child: globalOutlinedButton(
                  onPressed: () {
                    Dialogs.question(
                            widget.model.tr('End order?'), widget.model)
                        .then((value) {
                      if (value ?? false) {
                        if (widget.o['f_state'] == 1) {
                          Navigator.pop(context, true);
                        } else {
                          if ((widget.o['f_amountcash'] ?? 0) +
                                  (widget.o['f_amountcard'] ?? 0) +
                                  (widget.o['f_amountidram'] ?? 0) <
                              (widget.o['f_amounttotal'] ?? 0)) {
                            Dialogs.show(
                                widget.model.tr('Select payment method'));
                          } else {
                            Navigator.pop(context, true);
                          }
                        }
                      }
                    });
                  },
                  title: widget.model.tr('Finish'))),
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
}
