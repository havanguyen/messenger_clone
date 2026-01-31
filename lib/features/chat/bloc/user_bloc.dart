import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/chat_repository.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final ChatRepository chatRepository;

  UserBloc({required this.chatRepository}) : super(UserInitial()) {
    on<GetAllUsersEvent>((event, emit) async {
      emit(UserLoading());
      try {
        final users = await chatRepository.getAllUsers();
        emit(UserLoaded(users: users));
      } catch (error) {
        emit(UserError(message: error.toString()));
      }
    });
  }
}
