import 'package:carwash/utils/web_query.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStateLoading extends AppState {}

class AppStateFinish extends AppState {
  final dynamic data;

  AppStateFinish(this.data);

  /// Иначе [props] = [] у [AppState] — все [AppStateShifts] с разным [data] равны по Equatable,
  /// [Bloc] отбрасывает emit (после last-30 не приходят get-list / get-report в UI).
  @override
  List<Object?> get props => [data];
}

class AppStateCash extends AppStateFinish {
  AppStateCash(super.data);
}

class AppStateCashSession extends AppStateFinish {
  AppStateCashSession(super.data);
}

class AppStateError extends AppState {
  final String error;

  AppStateError(this.error);

  @override
  List<Object?> get props => [error];
}

class AppStateClosed extends AppState {}

class AppStateShifts extends AppStateFinish {
  AppStateShifts(super.data);
}

class AppEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppEventQuery extends AppEvent {
  final dynamic data;
  final String route;

  AppEventQuery(this.route, this.data);
}

class AppEventQueryCash extends AppEventQuery {
  AppEventQueryCash(super.route, super.data);
}

class AppEventQueryOpenSession extends AppEventQuery {
  AppEventQueryOpenSession(super.route, super.data);
}

class AppEventQueryRemoveFromCash extends AppEventQuery {
  AppEventQueryRemoveFromCash(super.route, super.data);
}

class AppEventQueryShift extends AppEventQuery {
  AppEventQueryShift(super.route, super.data);
}

class AppEventChangePayment extends AppEventQuery {
  AppEventChangePayment(super.route, super.data);
}

/// Загрузка списка процессов (как TV/HTML), отдельно от [AppEventQueryShift].
class AppEventQueryGoodsProcess extends AppEventQuery {
  AppEventQueryGoodsProcess(super.route, super.data);
}

class AppStateGoodsProcess extends AppStateFinish {
  AppStateGoodsProcess(super.data);
}

class AppEventQueryCloseDay extends AppEventQuery {
  AppEventQueryCloseDay(super.route, super.data);
}

class AppAnimateState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppAnimateStateRaise extends AppAnimateState {}

class AppAnimateEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppAnimateEventRaise extends AppAnimateEvent {}

class AppAnimateBloc extends Bloc<AppAnimateEvent, AppAnimateState> {
  AppAnimateBloc() : super(AppAnimateState()) {
    on<AppAnimateEvent>((event, emit) => emit(AppAnimateState()));
    on<AppAnimateEventRaise>((event, emit) => emit(AppAnimateStateRaise()));
  }
}

bool _httpJsonStatusOk(dynamic status) {
  if (status == 1 || status == true) return true;
  if (status is num && status.toInt() == 1) return true;
  final s = '$status'.trim().toLowerCase();
  return s == '1' || s == 'true';
}

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppState()) {
    on<AppEvent>((event, emit) => emit(AppState()));
    on<AppEventQuery>((event, emit) => query(event));
    on<AppEventQueryCash>((event, emit) => query(event));
    on<AppEventQueryRemoveFromCash>((event, emit) => query(event));
    on<AppEventQueryCloseDay>((event, emit) => query(event));
    on<AppEventQueryShift>((event, emit) => query(event));
    on<AppEventChangePayment>((event, emit) =>   query(event));
  }

  Future<void> query(AppEventQuery e) async {
    emit(AppStateLoading());
    final result = await WebHttpQuery(e.route).request(e.data);
    if (_httpJsonStatusOk(result['status'])) {
      if (e is AppEventQueryCash || e is AppEventQueryRemoveFromCash) {
        emit(AppStateCash(result['data']));
      } else if (e is AppEventQueryCloseDay) {
        emit(AppStateClosed());
      } else if (e is AppEventQueryOpenSession) {
        emit(AppStateCashSession(result));
      } else if (e is AppEventQueryGoodsProcess) {
        emit(AppStateGoodsProcess(result));
      } else if (e is AppEventQueryShift  || e is AppEventChangePayment) {
        emit(AppStateShifts(result));
      } else {
        emit(AppStateFinish(result['data']));
      }
    } else {
      emit(AppStateError(result['data']));
    }
  }
}
