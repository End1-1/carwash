import 'package:carwash/utils/web_query.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStateLoading extends AppState {

}

class AppStateFinish extends AppState {
  final dynamic data;
  AppStateFinish(this.data);
}

class AppStateError extends AppState {
  final String error;
  AppStateError(this.error);
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

class AppAnimateState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppAnimateStateRaise extends AppAnimateState{}

class AppAnimateEvent extends Equatable {
  @override
  List<Object?> get props => [];

}

class AppAnimateEventRaise extends  AppAnimateEvent {}

class AppAnimateBloc extends Bloc<AppAnimateEvent, AppAnimateState> {
  AppAnimateBloc() : super(AppAnimateState()) {
    on<AppAnimateEvent>((event, emit) => emit(AppAnimateState()));
    on<AppAnimateEventRaise>((event, emit) => emit(AppAnimateStateRaise()));
  }

}

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppState()) {
    on<AppEventQuery>((event, emit) => query(event));
  }

  Future<void> query(AppEventQuery e) async {
    emit(AppStateLoading());
    final result = await WebHttpQuery(e.route).request(e.data);
    if (result['status'] == 1) {
      emit(AppStateFinish(result['data']));
    } else {
      emit(AppStateError(result['data']));
    }

  }

}
