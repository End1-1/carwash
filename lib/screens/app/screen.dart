import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/model.dart';
import 'package:carwash/screens/app/question_bloc.dart';
import 'package:carwash/screens/menu.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:carwash/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AppScreen extends StatelessWidget {
  final AppModel model;

  const AppScreen( this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: Stack(children: [
            body(),
            WMAppMenu(model, menuWidgets()),
            BlocBuilder<AppBloc, AppState>(builder: (context, state) {
              if (state is AppStateError) {
                return errorDialog(state.error);
              }
              return Container();
            }),
            BlocBuilder<QuestionBloc, QuestionState>(builder: (builder, state) {
              if (state is QuestionStateRaise) {
                return questionDialog(state.question, state.ifYes, state.ifNo);
              }
              return Container();
            }),
            BlocBuilder<QuestionBloc, QuestionState>(builder: (builder, state) {
              if (state is QuestionStateList) {
                return listDialog(state.variants, state.callback);
              }
              return Container();
            }),
          ])),
    );
  }

  PreferredSizeWidget appBar();

  Widget body();

  List<Widget> menuWidgets() => [];

  Widget errorDialog(String text) {
    return Container(
        color: Colors.black26,
        child: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                        Styling.columnSpacingWidget(),
                        Container(
                            constraints: BoxConstraints(
                                maxHeight:
                                MediaQuery.sizeOf(prefs.context()).height *
                                    0.7),
                            child: SingleChildScrollView(
                                child: Styling.textCenter(text))),
                        Styling.columnSpacingWidget(),
                        Styling.textButton(model.closeErrorDialog, model.tr('Close'))
                      ],
                    ),
                  )
                ])));
  }

  Widget questionDialog(String text, VoidCallback ifYes, VoidCallback? ifNo) {
    return Container(
        color: Colors.black26,
        child: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.question_answer_outlined,
                          color: Colors.green,
                        ),
                        Styling.columnSpacingWidget(),
                        Container(
                            constraints: BoxConstraints(
                                maxHeight:
                                MediaQuery.sizeOf(prefs.context()).height *
                                    0.7),
                            child: SingleChildScrollView(
                                child: Styling.textCenter(text))),
                        Styling.columnSpacingWidget(),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Styling.textButton(() {
                            model.closeQuestionDialog();
                            ifYes();
                          }, model.tr('Yes')),
                          Styling.textButton(() {
                            model.closeQuestionDialog();
                            if (ifNo != null) {
                              ifNo!();
                            }
                          }, model.tr('Cancel'))
                        ])
                      ],
                    ),
                  )
                ])));
  }

  Widget listDialog(List<String> variants, Function(int) callback) {
    return Container(
        color: Colors.black26,
        child: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.question_answer_outlined,
                          color: Colors.green,
                        ),
                        Styling.columnSpacingWidget(),
                        Container(
                            constraints: BoxConstraints(
                                maxHeight:
                                MediaQuery.sizeOf(prefs.context()).height *
                                    0.7),
                            child: SingleChildScrollView(
                                child: Column(children: [
                                  for (int i = 0; i < variants.length; i++)
                                    InkWell(
                                        onTap: () {
                                          model.closeQuestionDialog();
                                          callback(i);
                                        },
                                        child: Container(
                                            margin:
                                            const EdgeInsets.fromLTRB(0, 5, 0, 5),
                                            child: Styling.textCenter(variants[i])))
                                ]))),
                        Styling.columnSpacingWidget(),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Styling.textButton(() {
                            model.closeQuestionDialog();
                            callback(-1);
                          }, model.tr('Cancel'))
                        ])
                      ],
                    ),
                  )
                ])));
  }
}
