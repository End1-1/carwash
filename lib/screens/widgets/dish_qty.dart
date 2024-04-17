import 'package:carwash/utils/global.dart';
import 'package:flutter/material.dart';

class DishQty extends StatefulWidget {
  Function(double) changeQty;
  var qty = 1.0;

  DishQty(this.changeQty, this.qty, {super.key});

  @override
  State<StatefulWidget> createState() => _DishQtyState();
}

class _DishQtyState extends State<DishQty> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
            onPressed: () {
              if (widget.qty < 99) {
                widget.qty += 1;
                widget.changeQty(widget.qty);
                setState(() {});
              }
            },
            icon: const Icon(Icons.plus_one, color: Colors.white, size: 30,)),
        Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                border:
                Border.fromBorderSide(BorderSide(color: Colors.white70))),
            child: Text(
              widget.qty.toString().replaceAll(doubleRegExp, ''),
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
        IconButton(
            onPressed: () {
              if (widget.qty > 1) {
                widget.qty -= 1;
                widget.changeQty(widget.qty);
                setState(() {});
              }
            },
            icon: const Icon(Icons.exposure_minus_1, color: Colors.white, size: 30,)),

      ],
    );
  }
}