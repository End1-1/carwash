import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/widgets/app_nav_popup_menu.dart';
import 'package:carwash/widgets/text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

part 'status.model.dart';

class StatusScreen extends AppScreen {
  final _model = StatusModel();

  StatusScreen(super.model, {super.key}) {
    getReport();
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
        title: Text(model.locale().report),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: getReport,
          ),
          AppNavPopupMenuButton(model: model),
        ]);
  }

  @override
  Widget body() {
    return Column(children: [
      const SizedBox(height: 5),
      Row(
        children: [
          Expanded(
              child: MTextFormField(
            controller: _model.startDateTextController,
            hintText: model.locale().startDate,
            readOnly: true,
            onTap: setStartDate,
          )),
          const SizedBox(width: 5),
          Expanded(
              child: MTextFormField(
                  controller: _model.endDateTextController,
                  hintText: model.locale().endDate,
                  readOnly: true,
                  onTap: setEndDate)),
        ],
      ),
      const SizedBox(width: 5),
      BlocBuilder<AppBloc, AppState>(builder: (builder, state) {
        if (state is AppStateError) {
          return Container(child: Text(state.error));
        } else if (state is AppStateFinish) {
          return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    SizedBox(
                        width: 120,
                        child: Text(
                          model.locale().input,
                          style: const TextStyle(
                              color: StatusModel.colorGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        )),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 120,
                              child: Text(model.locale().amountTotal,
                                  style: const TextStyle(
                                      color: StatusModel.colorGreen,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(model.locale().cash,
                                  style: const TextStyle(
                                      color: StatusModel.colorGreen,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(model.locale().card,
                                  style: const TextStyle(
                                      color: StatusModel.colorGreen,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(model.locale().idram,
                                  style: const TextStyle(
                                      color: StatusModel.colorGreen,
                                      fontWeight: FontWeight.bold))),
                        ]),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 120,
                              child: Text(state.data['total'][0][0],
                                  style: const TextStyle(
                                      color: StatusModel.colorGreen,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(state.data['total'][0][1],
                                  style: const TextStyle(
                                      color: StatusModel.colorGreen,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(state.data['total'][0][2],
                                  style: const TextStyle(
                                      color: StatusModel.colorGreen,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(state.data['total'][0][3],
                                  style: const TextStyle(
                                      color: StatusModel.colorGreen,
                                      fontWeight: FontWeight.bold))),
                        ]),
                    //fiscal
                    SizedBox(
                        width: 120,
                        child: Text(
                          model.locale().input,
                          style: const TextStyle(
                              color: StatusModel.colorRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        )),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 120,
                              child: Text(model.locale().amountTotal,
                                  style: const TextStyle(
                                      color: StatusModel.colorRed,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(model.locale().cash,
                                  style: const TextStyle(
                                      color: StatusModel.colorRed,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(model.locale().card,
                                  style: const TextStyle(
                                      color: StatusModel.colorRed,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(model.locale().idram,
                                  style: const TextStyle(
                                      color: StatusModel.colorRed,
                                      fontWeight: FontWeight.bold))),
                        ]),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 120,
                              child: Text(state.data['totalfiscal'][0][0],
                                  style: const TextStyle(
                                      color: StatusModel.colorRed,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(state.data['totalfiscal'][0][1],
                                  style: const TextStyle(
                                      color: StatusModel.colorRed,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(state.data['totalfiscal'][0][2],
                                  style: const TextStyle(
                                      color: StatusModel.colorRed,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: 100,
                              child: Text(state.data['totalfiscal'][0][3],
                                  style: const TextStyle(
                                      color: StatusModel.colorRed,
                                      fontWeight: FontWeight.bold))),
                        ]),
                    Divider(
                      height: 2,
                      color: Colors.black26,
                      thickness: 2,
                    ),


                        //Output
                        SizedBox(
                            width: 120,
                            child: Text(
                              model.locale().output,
                              style: const TextStyle(
                                  color: StatusModel.colorRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            )),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  width: 120,
                                  child: Text(model.locale().salary,
                                      style: const TextStyle(
                                          color: StatusModel.colorRed,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(width: 5),
                              SizedBox(
                                  width: 100,
                                  child: Text(model.locale().other,
                                      style: const TextStyle(
                                          color: StatusModel.colorRed,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(width: 5),
                              SizedBox(
                                  width: 100,
                                  child: Text(model.locale().selfcost,
                                      style: const TextStyle(
                                          color: StatusModel.colorRed,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(width: 5),

                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  width: 120,
                                  child: Text('0',
                                      style: const TextStyle(
                                          color: StatusModel.colorRed,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(width: 5),
                              SizedBox(
                                  width: 100,
                                  child: Text('0',
                                      style: const TextStyle(
                                          color: StatusModel.colorRed,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(width: 5),
                              SizedBox(
                                  width: 100,
                                  child: Text('0',
                                      style: const TextStyle(
                                          color: StatusModel.colorRed,
                                          fontWeight: FontWeight.bold))),
                              const SizedBox(width: 5),

                            ]),

                        //Profit
                        const SizedBox(height: 5),
                        SizedBox(
                            width: 150,
                            child: Text(
                              model.locale().profit,
                              style: const TextStyle(
                                  color: StatusModel.colorGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24),
                            )),
                        SizedBox(
                            width: 150,
                            child: Text(
                              state.data['total'][0][0],
                              style: const TextStyle(
                                  color: StatusModel.colorGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24),
                            )),
                        const SizedBox(height: 5),
                  ])));
        }
        return Container();
      })
    ]);
  }
}
