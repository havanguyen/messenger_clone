library;
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/core/network/network_info.dart';
import 'package:messenger_clone/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:messenger_clone/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:messenger_clone/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';
import 'package:messenger_clone/features/auth/domain/usecases/login_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/register_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/logout_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/check_credentials_usecase.dart';
import 'package:messenger_clone/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:messenger_clone/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/reauthenticate_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/update_user_auth_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/get_user_id_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:messenger_clone/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:messenger_clone/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:messenger_clone/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:messenger_clone/features/chat/domain/repositories/chat_repository.dart';
import 'package:messenger_clone/features/chat/domain/usecases/get_chat_items_usecase.dart';
import 'package:messenger_clone/features/chat/domain/usecases/get_friends_usecase.dart';
import 'package:messenger_clone/features/chat/presentation/bloc/chat_item_bloc.dart';
import 'package:messenger_clone/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:messenger_clone/features/messages/data/datasources/message_local_datasource.dart';
import 'package:messenger_clone/features/messages/data/repositories/message_repository_impl.dart';
import 'package:messenger_clone/features/messages/domain/repositories/message_repository.dart';
import 'package:messenger_clone/features/messages/domain/usecases/load_messages_usecase.dart';
import 'package:messenger_clone/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:messenger_clone/features/messages/presentation/bloc/message_bloc.dart';

import 'package:messenger_clone/features/menu/domain/usecases/search_users_usecase.dart';
import 'package:messenger_clone/features/menu/domain/usecases/create_group_usecase.dart';
import 'package:messenger_clone/features/menu/domain/usecases/fetch_user_data_usecase.dart';
import 'package:messenger_clone/features/menu/domain/usecases/get_pending_friend_requests_usecase.dart';
import 'package:messenger_clone/features/menu/presentation/bloc/create_group_bloc.dart';
import 'package:messenger_clone/features/meta_ai/data/datasources/meta_ai_remote_datasource.dart';
import 'package:messenger_clone/features/meta_ai/data/datasources/meta_ai_local_datasource.dart';
import 'package:messenger_clone/features/meta_ai/data/repositories/meta_ai_repository_impl.dart';
import 'package:messenger_clone/features/meta_ai/domain/repositories/meta_ai_repository.dart';
import 'package:messenger_clone/features/meta_ai/domain/usecases/send_ai_message_usecase.dart';
import 'package:messenger_clone/features/meta_ai/presentation/bloc/meta_ai_bloc.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messenger_clone/features/story/data/datasources/story_remote_datasource.dart';
import 'package:messenger_clone/features/story/data/datasources/story_remote_datasource_impl.dart';
import 'package:messenger_clone/features/story/data/repositories/story_repository_impl.dart';
import 'package:messenger_clone/features/story/domain/repositories/story_repository.dart';
import 'package:messenger_clone/features/user/data/datasources/user_remote_datasource.dart';
import 'package:messenger_clone/features/user/data/repositories/user_repository_impl.dart';
import 'package:messenger_clone/features/user/domain/repositories/user_repository.dart';
import 'package:messenger_clone/features/friend/data/datasources/friend_remote_datasource.dart';
import 'package:messenger_clone/features/friend/data/repositories/friend_repository_impl.dart';
import 'package:messenger_clone/features/friend/domain/repositories/friend_repository.dart';
import 'package:messenger_clone/features/settings/data/datasources/device_remote_datasource.dart';
import 'package:messenger_clone/features/settings/data/datasources/device_remote_datasource_impl.dart';
import 'package:messenger_clone/features/settings/data/repositories/device_repository_impl.dart';
import 'package:messenger_clone/features/settings/domain/repositories/device_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      resetPasswordUseCase: sl(),
      deleteAccountUseCase: sl(),
      reauthenticateUseCase: sl(),
      updateUserAuthUseCase: sl(),
      getUserIdUseCase: sl(),
      checkCredentialsUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));
  sl.registerLazySingleton(() => ReauthenticateUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserAuthUseCase(sl()));
  sl.registerLazySingleton(() => GetUserIdUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => CheckCredentialsUseCase(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );
  sl.registerFactory(
    () => ChatItemBloc(getChatItemsUseCase: sl(), getFriendsUseCase: sl()),
  );
  sl.registerLazySingleton(() => GetChatItemsUseCase(sl()));
  sl.registerLazySingleton(() => GetFriendsUseCase(sl()));
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(),
  );
  sl.registerFactory(
    () => MessageBloc(
      chatRepository: sl(),
      loadMessagesUseCase: sl(),
      sendMessageUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoadMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<MessageLocalDataSource>(
    () => MessageLocalDataSourceImpl(),
  );
  sl.registerFactory(
    () => CreateGroupBloc(
      getFriendsUseCase: sl(),
      createGroupUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => SearchUsersUseCase(sl()));
  sl.registerLazySingleton(() => CreateGroupUseCase(sl()));
  sl.registerLazySingleton(() => FetchUserDataUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingFriendRequestsUseCase(sl()));
  sl.registerFactory(
    () => MetaAiBloc(repository: sl(), sendAiMessageUseCase: sl()),
  );
  sl.registerLazySingleton(() => SendAiMessageUseCase(sl()));
  sl.registerLazySingleton<MetaAiRepository>(
    () => MetaAiRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<MetaAiRemoteDataSource>(
    () => MetaAiRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<MetaAiLocalDataSource>(
    () => MetaAiLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
  );
  sl.registerLazySingleton<FriendRepository>(
    () => FriendRepositoryImpl(remoteDataSource: sl(), userRepository: sl()),
  );
  sl.registerLazySingleton<FriendRemoteDataSource>(
    () => FriendRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
  );
  sl.registerLazySingleton<StoryRepository>(
    () => StoryRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<StoryRemoteDataSource>(
    () => StoryRemoteDataSourceImpl(
      supabase: Supabase.instance.client,
      firestore: FirebaseFirestore.instance,
      friendRepository: sl(),
    ),
  );
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DeviceRemoteDataSource>(
    () => DeviceRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
  );
}
