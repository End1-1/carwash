
import 'package:carwash/screens/app/appbloc.dart';
import 'package:carwash/screens/app/screen.dart';
import 'package:carwash/utils/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/preferred_size.dart';
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
    return AppBar();
  }

  @override
  Widget body() {

    return BlocBuilder<AppBloc, AppState>(builder: (builder, state) {
      if (state is AppStateError) {
        return Container(child: Text(state.error));
      }
      return Container();
    });
  }
}