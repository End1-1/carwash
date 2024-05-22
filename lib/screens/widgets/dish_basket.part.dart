part of 'dish_basket.dart';

class CookingTimeState extends Equatable {

  @override
  List<Object> get props => [];
}

class CookingTimeUpdatedState extends CookingTimeState {}

class CookingTimeEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class CookingTimeUpdate extends CookingTimeEvent {}

class CookingTimeBlok extends Bloc<CookingTimeEvent, CookingTimeState> {
  CookingTimeBlok(super.initialState) {
    on<CookingTimeEvent>((event, emit) => emit(CookingTimeState()));
    on<CookingTimeUpdate>((event, emit) => emit(CookingTimeUpdatedState()));
  }

}

extension DishBasketExtension on DishBasket {

}