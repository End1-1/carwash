part of 'status.dart';

class StatusModel {
  final startDateTextController = TextEditingController();
  final endDateTextController = TextEditingController();

  var startDate = DateTime.now();
  var endDate = DateTime.now();

  static const colorRed = Color(0xff850000);
  static const colorGreen = Color(0xff006700);

  StatusModel() {
    setDateText();
  }

  void setDateText() {
    startDateTextController.text = DateFormat('dd/MM/yyyy').format(startDate);
    endDateTextController.text = DateFormat('dd/MM/yyyy').format(endDate);
  }
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

  void setStartDate() {
    showDatePicker(
        context: prefs.context(),
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        firstDate: DateTime.now().add(const Duration(days: -365 * 3)),
        lastDate: DateTime.now().add(const Duration(days: 1)))
        .then((value) {
      if (value != null) {
        _model.startDate = value;
        _model.setDateText();
      }
    });
  }

  void setEndDate() {
    showDatePicker(
        context: prefs.context(),
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        firstDate: DateTime.now().add(const Duration(days: -365 * 3)),
        lastDate: DateTime.now().add(const Duration(days: 1)))
        .then((value) {
      if (value != null) {
        _model.endDate = value;
        _model.setDateText();
      }
    });
  }
}