import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/user.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/task_repository.dart';

// ── State ──────────────────────────────────────────────────────────────────

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UsersLoaded extends UserState {
  final List<User> users;
  final User? activeUser;
  const UsersLoaded({required this.users, this.activeUser});
  @override
  List<Object?> get props => [users, activeUser];
}

class UserAuthenticated extends UserState {
  final User user;
  const UserAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;
  const UserError(this.message);
  @override
  List<Object?> get props => [message];
}

class UserPinError extends UserState {
  final int attemptsLeft;
  const UserPinError({required this.attemptsLeft});
  @override
  List<Object?> get props => [attemptsLeft];
}

// ── Cubit ──────────────────────────────────────────────────────────────────

class UserCubit extends Cubit<UserState> {
  final IUserRepository _repository;
  final ITaskRepository _taskRepository;
  int _failedAttempts = 0;

  UserCubit({
    required IUserRepository repository,
    required ITaskRepository taskRepository,
  })  : _repository = repository,
        _taskRepository = taskRepository,
        super(const UserInitial());

  // ── Kullanıcı Listesi ─────────────────────────────────────────────────────

  Future<void> loadUsers() async {
    emit(const UserLoading());
    final usersResult = await _repository.getAllUsers();
    final activeResult = await _repository.getActiveUser();

    usersResult.fold(
      (failure) => emit(UserError(failure.message)),
      (users) {
        final activeUser = activeResult.fold((_) => null, (u) => u);
        // Aktif kullanıcı varsa otomatik olarak authenticate et
        // (her oturum açılışında PIN girişi gerekmez)
        if (activeUser != null) {
          emit(UserAuthenticated(activeUser));
        } else {
          emit(UsersLoaded(users: users, activeUser: null));
        }
      },
    );
  }

  // ── Profil Seçme & PIN Doğrulama ──────────────────────────────────────────

  Future<void> selectUser(String userId, String pin) async {
    emit(const UserLoading());

    final verifyResult = await _repository.verifyPin(userId, pin);
    final isValid = verifyResult.fold((_) => false, (v) => v);

    if (!isValid) {
      _failedAttempts++;
      const maxAttempts = 5;
      emit(UserPinError(attemptsLeft: maxAttempts - _failedAttempts));
      return;
    }

    _failedAttempts = 0;
    await _repository.setActiveUser(userId);

    final userResult = await _repository.getUserById(userId);
    userResult.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserAuthenticated(user)),
    );
  }

  // ── Profil Yönetimi ───────────────────────────────────────────────────────

  Future<void> createUser(User user) async {
    final result = await _repository.createUser(user);
    await result.fold(
      (failure) async => emit(UserError(failure.message)),
      (createdUser) async {
        final usersResult = await _repository.getAllUsers();
        final userCount = usersResult.fold((_) => 0, (u) => u.length);
        if (userCount == 1) {
          await _repository.setActiveUser(createdUser.id);
          await _seedDemoTasks(createdUser.id);
          emit(UserAuthenticated(createdUser));
        } else {
          await loadUsers();
        }
      },
    );
  }

  Future<void> _seedDemoTasks(String userId) async {
    const uuid = Uuid();
    final tasks = [
      // 10 Mart
      _makeTask(uuid, userId, 'Berberi ara', '2026-03-10T19:30:00', TaskPriority.high, TaskCategory.personal),
      _makeTask(uuid, userId, 'Market alışverişi', '2026-03-10T18:00:00', TaskPriority.medium, TaskCategory.personal),
      // 11 Mart
      _makeTask(uuid, userId, 'Doktor randevusu', '2026-03-11T14:00:00', TaskPriority.high, TaskCategory.personal),
      _makeTask(uuid, userId, 'Spor salonu', '2026-03-11T08:00:00', TaskPriority.medium, TaskCategory.personal),
      // 12 Mart
      _makeTask(uuid, userId, 'Proje sunumu hazırlık', '2026-03-12T10:00:00', TaskPriority.high, TaskCategory.work),
      _makeTask(uuid, userId, 'Fatura öde', '2026-03-12T15:00:00', TaskPriority.medium, TaskCategory.work),
      // 13 Mart
      _makeTask(uuid, userId, 'Ekip standup toplantısı', '2026-03-13T09:30:00', TaskPriority.high, TaskCategory.work),
      _makeTask(uuid, userId, 'Kitap okuma', '2026-03-13T21:00:00', TaskPriority.low, TaskCategory.personal),
      // 14 Mart
      _makeTask(uuid, userId, 'Aile yemeği', '2026-03-14T19:00:00', TaskPriority.high, TaskCategory.personal),
      _makeTask(uuid, userId, 'Araba bakım servisi', '2026-03-14T11:00:00', TaskPriority.medium, TaskCategory.personal),
      // 15 Mart
      _makeTask(uuid, userId, 'TÜBİTAK rapor teslimi', '2026-03-15T17:00:00', TaskPriority.high, TaskCategory.work),
      _makeTask(uuid, userId, 'Spor salonu', '2026-03-15T08:00:00', TaskPriority.medium, TaskCategory.personal),
      // 16 Mart
      _makeTask(uuid, userId, 'Haftalık planlama', '2026-03-16T10:00:00', TaskPriority.medium, TaskCategory.work),
      _makeTask(uuid, userId, 'Alışveriş listesi hazırla', '2026-03-16T16:00:00', TaskPriority.low, TaskCategory.personal),
      // 17 Mart
      _makeTask(uuid, userId, 'Proje kodu review', '2026-03-17T14:00:00', TaskPriority.high, TaskCategory.work),
      _makeTask(uuid, userId, 'Akşam yürüyüşü', '2026-03-17T19:00:00', TaskPriority.low, TaskCategory.personal),
    ];
    for (final task in tasks) {
      await _taskRepository.createTask(task);
    }
  }

  Task _makeTask(Uuid uuid, String userId, String title, String dueDate,
      TaskPriority priority, TaskCategory category) {
    return Task(
      id: uuid.v4(),
      userId: userId,
      title: title,
      priority: priority,
      category: category,
      dueDate: DateTime.parse(dueDate),
      createdAt: DateTime.now(),
    );
  }

  Future<void> updateUser(User user) async {
    final result = await _repository.updateUser(user);
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (_) => loadUsers(),
    );
  }

  Future<void> deleteUser(String userId) async {
    final result = await _repository.deleteUser(userId);
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (_) => loadUsers(),
    );
  }

  // ── Oturum Kapatma ────────────────────────────────────────────────────────

  Future<void> logout() async {
    emit(const UserLoading());
    // Aktif kullanıcıyı temizle (boş ID = oturum yok)
    await _repository.setActiveUser('');
    final usersResult = await _repository.getAllUsers();
    usersResult.fold(
      (failure) => emit(UserError(failure.message)),
      (users) => emit(UsersLoaded(users: users, activeUser: null)),
    );
  }
}
