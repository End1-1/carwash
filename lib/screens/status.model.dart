part of 'status.dart';

class StatusModel {
  final startDateTextController = TextEditingController();
  final endDateTextController = TextEditingController();

  var startDate = DateTime.now();
  var endDate = DateTime.now();
}

extension EStatus on StatusScreen {
  void getReport() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQuery('/engine/carwash/status-report.php',
      {
        'start': DateFormat('yyyy-MM-dd').format(_model.startDate),
        'end': DateFormat('yyyy-MM-dd').format(_model.endDate)
      }
    ));
  }
}