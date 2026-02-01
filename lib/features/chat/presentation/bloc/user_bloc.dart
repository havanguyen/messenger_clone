import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:messenger_clone/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

part 'user_event.dart';
part 'user_state.dart';
class UserBloc extends Bloc<UserEvent, UserState> {
  final ChatRemoteDataSource remoteDataSource;

  UserBloc({required this.remoteDataSource}) : super(UserInitial()) {
    on<GetAllUsersEvent>((event, emit) async {
      emit(UserLoading());
      try {
        final users = await remoteDataSource.getAllUsers();
        emit(UserLoaded(users: users));
      } catch (error) {
        emit(UserError(message: error.toString()));
      }
    });
  }
}
