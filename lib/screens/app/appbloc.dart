import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
