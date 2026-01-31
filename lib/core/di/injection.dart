/// Dependency Injection configuration using get_it.
library;
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/core/network/network_info.dart';

// Features - Auth
import 'package:messenger_clone/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:messenger_clone/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:messenger_clone/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';
import 'package:messenger_clone/features/auth/domain/usecases/login_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/register_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/logout_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/check_credentials_usecase.dart';
import 'package:messenger_clone/features/auth/presentation/bloc/auth_bloc.dart';
// ... existing imports ...

import 'package:messenger_clone/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/reauthenticate_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/update_user_auth_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/get_user_id_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/get_current_user_usecase.dart';

// Features - Chat
import 'package:messenger_clone/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:messenger_clone/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:messenger_clone/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:messenger_clone/features/chat/domain/repositories/chat_repository.dart';
import 'package:messenger_clone/features/chat/domain/usecases/get_chat_items_usecase.dart';
import 'package:messenger_clone/features/chat/domain/usecases/get_friends_usecase.dart';
import 'package:messenger_clone/features/chat/presentation/bloc/chat_item_bloc.dart';

// Features - Messages
import 'package:messenger_clone/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:messenger_clone/features/messages/data/datasources/message_local_datasource.dart';
import 'package:messenger_clone/features/messages/data/repositories/message_repository_impl.dart';
import 'package:messenger_clone/features/messages/domain/repositories/message_repository.dart';
import 'package:messenger_clone/features/messages/domain/usecases/load_messages_usecase.dart';
import 'package:messenger_clone/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:messenger_clone/features/messages/presentation/bloc/message_bloc.dart';

// Features - Menu

import 'package:messenger_clone/features/menu/domain/usecases/search_users_usecase.dart';
import 'package:messenger_clone/features/menu/domain/usecases/create_group_usecase.dart';
import 'package:messenger_clone/features/menu/domain/usecases/fetch_user_data_usecase.dart';
import 'package:messenger_clone/features/menu/domain/usecases/get_pending_friend_requests_usecase.dart';
import 'package:messenger_clone/features/menu/presentation/bloc/create_group_bloc.dart';

// Features - Meta AI
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
  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  //! Features - Auth
  // Bloc
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

  // Use cases
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

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      // networkInfo removed as it's not in AuthRepositoryImpl constructor
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );

  //! Features - Chat
  // Bloc
  sl.registerFactory(
    () => ChatItemBloc(getChatItemsUseCase: sl(), getFriendsUseCase: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetChatItemsUseCase(sl()));
  sl.registerLazySingleton(() => GetFriendsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(),
  );

  //! Features - Messages
  // Bloc
  sl.registerFactory(
    () => MessageBloc(
      chatRepository: sl(),
      loadMessagesUseCase: sl(),
      sendMessageUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoadMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));

  // Repository
  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<MessageRemoteDataSource>(
    () => MessageRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<MessageLocalDataSource>(
    () => MessageLocalDataSourceImpl(),
  );

  //! Features - Menu
  // Bloc
  // Bloc
  sl.registerFactory(
    () => CreateGroupBloc(
      getFriendsUseCase: sl(),
      createGroupUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SearchUsersUseCase(sl()));
  sl.registerLazySingleton(() => CreateGroupUseCase(sl()));
  sl.registerLazySingleton(() => FetchUserDataUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingFriendRequestsUseCase(sl()));

  //! Features - Meta AI
  // Bloc
  sl.registerFactory(
    () => MetaAiBloc(repository: sl(), sendAiMessageUseCase: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SendAiMessageUseCase(sl()));

  // Repository
  sl.registerLazySingleton<MetaAiRepository>(
    () => MetaAiRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<MetaAiRemoteDataSource>(
    () => MetaAiRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<MetaAiLocalDataSource>(
    () => MetaAiLocalDataSourceImpl(),
  );
  //! Features - User
  // Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
  );

  //! Features - Friend
  // Repository
  sl.registerLazySingleton<FriendRepository>(
    () => FriendRepositoryImpl(remoteDataSource: sl(), userRepository: sl()),
  );

  // Data sources
  sl.registerLazySingleton<FriendRemoteDataSource>(
    () => FriendRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
  );

  //! Features - Story
  // Repository
  sl.registerLazySingleton<StoryRepository>(
    () => StoryRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<StoryRemoteDataSource>(
    () => StoryRemoteDataSourceImpl(
      supabase: Supabase.instance.client,
      firestore: FirebaseFirestore.instance,
      friendRepository: sl(),
    ),
  );

  //! Features - Device
  // Repository
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<DeviceRemoteDataSource>(
    () => DeviceRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
  );
}
