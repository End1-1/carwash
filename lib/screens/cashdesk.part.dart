part of 'cashdesk.dart';

class CashState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CashStateDeals extends CashState {
  final List<Map<String, dynamic>> deals;

  CashStateDeals(this.deals);
}

class CashEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CashEventDeals extends CashEvent {
  final List<Map<String, dynamic>> deals;

  CashEventDeals(this.deals);
}

class CashBloc extends Bloc<CashEvent, CashState> {
  CashBloc() : super(CashState()) {
    on<CashEvent>((event, emit) => emit(CashState()));
    on<CashEventDeals>((event, emit) => emit(CashStateDeals(event.deals)));
  }
}

class CashdeskModel {
  final textController = TextEditingController();
  final amountController = TextEditingController();
  final deals = <Map<String, dynamic>>[];
  var date = DateTime.now();

  CashdeskModel() {
    print("DDDD");
  }

  void refresh() {
    BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryCash(
        '/engine/carwash/cashreport.php',
        {'session': 1, 'date': prefs.dateStr(date)}));
  }

  void newRow() {
    for (final d in deals) {
      if (d['id'].isEmpty) {
        Dialogs.show('Պահպանեք նախորդ ավելցված տողը');
        return;
      }
    }
    deals.add({'id': '', 'remarks': '', 'amount': 0});
    BlocProvider.of<CashBloc>(prefs.context()).add(CashEventDeals(deals));
  }

  void setPurpose() {
    final variants = <String>['Աշխատավարձ'];
    BlocProvider.of<QuestionBloc>(prefs.context()).add(QuestionEventList(
      variants, (index) {
        if (index > -1) {
          textController.text = variants[index];
        }
    }
    ));
  }

  void save() {
    final d =
        deals.firstWhere((element) => element['id'].isEmpty, orElse: () => {});
    if (d.isEmpty) {
      return;
    }
    deals.clear();
    BlocProvider.of<CashBloc>(prefs.context()).add(CashEventDeals(deals));
    BlocProvider.of<AppBloc>(prefs.context())
        .add(AppEventQueryCash('/engine/cashdesk/create.php', {
      'cashin': 0,
      'date': prefs.dateStr(date),
      'amount': amountController.text,
      'remarks': textController.text,
      'cashout': 1,
      'refresh': 'carwashcashdesk',
      'session': 1
    }));
  }

  void removeOut(Map<String, dynamic> d) {
    BlocProvider.of<QuestionBloc>(prefs.context())
        .add(QuestionEventRaise('Հաստատեք տողի հեռացումը \n ${d['f_remarks']} \n ${d['f_amount']}', () {
      BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryRemoveFromCash(
          '/engine/cashdesk/remove-doc.php',
          {'session':1,'refresh': 'carwashcashdesk', 'id': d['f_id']}));
    }, () {}));
  }

  void closeDay() {
    BlocProvider.of<QuestionBloc>(prefs.context()).add(QuestionEventRaise('Փակել օրը՞', () {
      BlocProvider.of<AppBloc>(prefs.context()).add(AppEventQueryCloseDay('/engine/carwash/close-day.php',
          {
            'session':1,'refresh': 'carwashcashdesk'
          }));
    }, () { }));
  }

  double total(List<dynamic> t) {
    return t.fold(0, (previousValue, element) => previousValue + (double.tryParse(element['f_amount']) ?? 0));
  }
}
