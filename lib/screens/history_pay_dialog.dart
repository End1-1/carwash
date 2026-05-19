import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/widgets/payment.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/widgets/dialogs.dart';
import 'package:carwash/widgets/loading.dart';
import 'package:flutter/material.dart';

class HistoryPayDialogBody extends StatefulWidget {
  final AppModel model;
  final Map<String, dynamic> orderMap;
  final String headerId;
  final int? processStatus;
  final int? processSubstatus;

  const HistoryPayDialogBody({
    super.key,
    required this.model,
    required this.orderMap,
    required this.headerId,
    this.processStatus,
    this.processSubstatus,
  });

  @override
  State<HistoryPayDialogBody> createState() => _HistoryPayDialogBodyState();
}

class _HistoryPayDialogBodyState extends State<HistoryPayDialogBody> {
  late Map<String, dynamic> o;

  @override
  void initState() {
    super.initState();
    o = Map<String, dynamic>.from(widget.orderMap);
  }

  double _m(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '').trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.model.locale();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Payment(
          o,
          widget.model,
          showComplimentary: false,
          carNumberDisplay: widget.model.carPlateFromOrderMap(o),
          trailingAfterAmount: StreamBuilder<Object?>(
            stream: widget.model.fiscalController.stream,
            builder: (context, _) {
              return InkWell(
                onTap: widget.model.togglePrintFiscalOnly,
                child: Image.asset(
                  widget.model.printFiscal
                      ? 'assets/icons/basketball.png'
                      : 'assets/icons/football.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Нельзя [globalOutlinedButton]: внутри SizedBox.expand — ломается при h=∞ у диалога.
        SizedBox(
          width: double.infinity,
          height: kButtonHeight,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.center,
              backgroundColor: Colors.indigo,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
              ),
            ),
            onPressed: () async {
              final cash = _m(o['f_amountcash']);
              final card = _m(o['f_amountcard']);
              final idram = _m(o['f_amountidram']);
              final other = _m(o['f_amountother']);
              final total = _m(o['f_amounttotal']);
              if ((cash + card + idram + other - total).abs() > 0.02) {
                Dialogs.show(loc.selectPaymentMethod);
                return;
              }
              if (other > 0.009) {
                Dialogs.show(loc.selectPaymentMethod);
                return;
              }
              await Loading.showUntilDisplayed(loc.loading);
              final err = await widget.model.payComplimentaryOrderWithRealPayment(
                headerId: widget.headerId,
                orderSnapshot: Map<String, dynamic>.from(o),
                cash: cash,
                card: card,
                idram: idram,
                processStatus: widget.processStatus,
                processSubstatus: widget.processSubstatus,
              );
              Loading.dismiss();
              if (!context.mounted) return;
              if (err != null) {
                Dialogs.show(err);
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(
              loc.finish,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
