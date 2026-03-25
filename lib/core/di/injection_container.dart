import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../network/api_service.dart';
import '../security/security_layer.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/remote/ai_remote_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../presentation/blocs/task/task_bloc.dart';
import '../../presentation/blocs/user/user_cubit.dart';
import '../../presentation/blocs/voice/voice_cubit.dart';

/// GetIt servis konteyneri — uygulama genelinde bağımlılık enjeksiyonu.
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Dış Bağımlılıklar ─────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );

  // ── Güvenlik Katmanı ──────────────────────────────────────────────────────
  sl.registerSingleton<SecurityLayer>(
    SecurityLayer(
      secureStorage: sl<FlutterSecureStorage>(),
      prefs: sl<SharedPreferences>(),
    ),
  );

  // ── Ağ ───────────────────────────────────────────────────────────────────
  sl.registerSingleton<ApiService>(
    ApiService(security: sl<SecurityLayer>()),
  );

  // ── Veritabanı ────────────────────────────────────────────────────────────
  sl.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);

  // ── Ses Bileşenleri ───────────────────────────────────────────────────────
  sl.registerSingleton<stt.SpeechToText>(stt.SpeechToText());
  sl.registerSingleton<FlutterTts>(FlutterTts());

  // ── Remote DataSources ────────────────────────────────────────────────────
  sl.registerSingleton<IAiRemoteDataSource>(
    AiRemoteDataSource(apiService: sl<ApiService>()),
  );

  // ── Repositories ─────────────────────────────────────────────────────────
  sl.registerSingleton<ITaskRepository>(
    TaskRepositoryImpl(db: sl<DatabaseHelper>()),
  );
  sl.registerSingleton<IUserRepository>(
    UserRepositoryImpl(
      db: sl<DatabaseHelper>(),
      prefs: sl<SharedPreferences>(),
    ),
  );

  // ── Use Cases ─────────────────────────────────────────────────────────────
  sl.registerFactory(() => GetTasksByUser(sl<ITaskRepository>()));
  sl.registerFactory(() => GetTodayTasks(sl<ITaskRepository>()));
  sl.registerFactory(() => CreateTaskUseCase(sl<ITaskRepository>()));
  sl.registerFactory(() => UpdateTaskUseCase(sl<ITaskRepository>()));
  sl.registerFactory(() => DeleteTaskUseCase(sl<ITaskRepository>()));
  sl.registerFactory(() => ToggleTaskCompletion(sl<ITaskRepository>()));
  sl.registerFactory(() => SearchTasks(sl<ITaskRepository>()));

  // ── Blocs / Cubits ────────────────────────────────────────────────────────
  sl.registerFactory(
    () => TaskBloc(
      getTasksByUser: sl(),
      getTodayTasks: sl(),
      createTask: sl(),
      updateTask: sl(),
      deleteTask: sl(),
      toggleTask: sl(),
      searchTasks: sl(),
    ),
  );

  sl.registerFactory(
    () => UserCubit(
      repository: sl<IUserRepository>(),
      taskRepository: sl<ITaskRepository>(),
    ),
  );

  sl.registerFactoryParam<VoiceCubit, TaskBloc, void>(
    (taskBloc, _) => VoiceCubit(
      speechToText: sl<stt.SpeechToText>(),
      tts: sl<FlutterTts>(),
      aiDataSource: sl<IAiRemoteDataSource>(),
      taskBloc: taskBloc,
    ),
  );
}
