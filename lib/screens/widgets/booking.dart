import 'package:carwash/screens/app/model.dart';
import 'package:carwash/utils/global.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Booking extends StatelessWidget {
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final AppModel model;

  Booking(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: MTextFormField(controller: dateController, hintText: model.tr('Date'))),
          IconButton(onPressed: (){}, icon: const Icon(Icons.edit_outlined))
        ],)  ,
        const SizedBox(height: 10,),
        Row(children: [
          Expanded(child: MTextFormField(controller: timeController, hintText: model.tr('Time'))),
          IconButton(onPressed: (){
            selectDate().then((value) {

            });
          }, icon: const Icon(Icons.edit_outlined))
        ],)  ,
      ],
    );
  }

}