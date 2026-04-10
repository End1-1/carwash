import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/utils/kbd.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:flutter/material.dart';

class Payment extends StatefulWidget {
  final Map<String, dynamic> o;
  final AppModel model;
  final bool readyonly;
  /// Если `false`, кнопка «не оплачено» (прочее) скрыта — только кэш / карта / идрам.
  final bool showComplimentary;
  /// Если задан — показываем номер только текстом (без клавиатуры и [carNumberController]).
  final String? carNumberDisplay;

  const Payment(this.o, this.model,
      {super.key,
      this.readyonly = false,
      this.showComplimentary = true,
      this.carNumberDisplay});

  @override
  State<StatefulWidget> createState() => _Payment();
}

class _Payment extends State<Payment> {
  final moneyController = TextEditingController();

  static ButtonStyle s1 = OutlinedButton.styleFrom(
      padding: EdgeInsets.zero,
      alignment: Alignment.center,
      backgroundColor: Colors.black26,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.0))));

  static ButtonStyle s2 = OutlinedButton.styleFrom(
      alignment: Alignment.center,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.indigo,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.0))));

  static TextStyle t1 = const TextStyle(
      fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black);
  static TextStyle t2 = const TextStyle(
      fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    moneyController.text = '${widget.o['f_amounttotal'] ?? 0}';
    return Column(children: [
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: widget.carNumberDisplay != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.carNumberDisplay!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  )
                : MTextFormField(
                    controller: widget.model.carNumberController,
                    readOnly: true,
                    onTap: () {
                      Kbd.getText().then((v) {
                        if (v != null) {
                          widget.model.carNumberController.text = v;
                        }
                      });
                    },
                    hintText: 'Պետհամարանիշ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  )),
        const SizedBox(width: 5),
        Expanded(
            child: MTextFormField(
                controller: moneyController,
                hintText: widget.model.locale().amount,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                readOnly: true))
      ]),
      const SizedBox(height: 10),
      Container(
          height: kButtonHeight,
          child: Row(
            children: [
              if (widget.showComplimentary) ...[
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          if (widget.readyonly) {
                            return;
                          }
                          widget.o['f_amountcash'] = 0;
                          widget.o['f_amountcard'] = 0;
                          widget.o['f_amountidram'] = 0;
                          widget.o['f_amountother'] = 0;
                          widget.o['f_amountother'] = widget.o['f_amounttotal'];
                          widget.model.printFiscal = false;
                          widget.model.fiscalController.add(null);
                          setState(() {});
                        },
                        style: (widget.o['f_amountother'] ?? 0) > 0 ? s2 : s1,
                        child: Text(widget.model.locale().paymentNotPaid,
                            style:
                                (widget.o['f_amountother'] ?? 0) > 0 ? t2 : t1))),
                const SizedBox(
                  width: 5,
                ),
              ],
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        if (widget.readyonly || widget.model.isOrderBusy) {
                          return;
                        }
                        widget.o['f_amountcash'] = 0;
                        widget.o['f_amountcard'] = 0;
                        widget.o['f_amountidram'] = 0;
                        widget.o['f_amountother'] = 0;
                        widget.o['f_amountcash'] = widget.o['f_amounttotal'];
                        widget.model.printFiscal = true;
                        widget.model.fiscalController.add(null);
                        setState(() {});
                      },
                      style: (widget.o['f_amountcash'] ?? 0) > 0 ? s2 : s1,
                      child: Text(widget.model.locale().cash,
                          style:
                              (widget.o['f_amountcash'] ?? 0) > 0 ? t2 : t1))),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        if (widget.readyonly || widget.model.isOrderBusy) {
                          return;
                        }
                        widget.o['f_amountcash'] = 0;
                        widget.o['f_amountcard'] = 0;
                        widget.o['f_amountidram'] = 0;
                        widget.o['f_amountother'] = 0;
                        widget.o['f_amountcard'] = widget.o['f_amounttotal'];
                        widget.model.printFiscal = true;
                        widget.model.fiscalController.add(null);
                        setState(() {});
                      },
                      style: (widget.o['f_amountcard'] ?? 0) > 0 ? s2 : s1,
                      child: Text(widget.model.locale().card,
                          style:
                              (widget.o['f_amountcard'] ?? 0) > 0 ? t2 : t1))),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        if (widget.readyonly || widget.model.isOrderBusy) {
                          return;
                        }
                        widget.o['f_amountcash'] = 0;
                        widget.o['f_amountcard'] = 0;
                        widget.o['f_amountidram'] = 0;
                        widget.o['f_amountother'] = 0;
                        widget.o['f_amountidram'] = widget.o['f_amounttotal'];
                        widget.model.printFiscal = true;
                        widget.model.fiscalController.add(null);
                        setState(() {});
                      },
                      style: (widget.o['f_amountidram'] ?? 0) > 0 ? s2 : s1,
                      child: Text(widget.model.locale().idram,
                          style:
                              (widget.o['f_amountidram'] ?? 0) > 0 ? t2 : t1))),

              /*
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        if (widget.readyonly || widget.model.isOrderBusy) {
                          return;
                        }
                        widget.o['f_amountcash'] = 0;
                        widget.o['f_amountcard'] = 0;
                        widget.o['f_amountidram'] = 0;
                        setState(() {});
                      },
                      style: (widget.o['f_amountidram'] ?? 0) == 0 &&
                              (widget.o['f_amountcash'] ?? 0) == 0 &&
                              (widget.o['f_amountcard'] ?? 0) == 0
                          ? s2
                          : s1,
                      child: Text(widget.model.locale().notNow,
                          style: (widget.o['f_amountidram'] ?? 0) == 0 &&
                                  (widget.o['f_amountcash'] ?? 0) == 0 &&
                                  (widget.o['f_amountcard'] ?? 0) == 0
                              ? t2
                              : t1))),


               */
            ],
          ))
    ]);
  }
}
