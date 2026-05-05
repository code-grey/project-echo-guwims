import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/repositories/admin_user_repository.dart';
import '../providers/auth_provider.dart';

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AdminUserRepository(dioClient);
});

final adminUserListProvider = FutureProvider<List<User>>((ref) async {
  final repo = ref.watch(adminUserRepositoryProvider);
  return repo.getAllUsers();
});

class AdminUserActionState {
  final bool isLoading;
  final String? error;

  const AdminUserActionState({this.isLoading = false, this.error});

  AdminUserActionState copyWith({bool? isLoading, String? error}) {
    return AdminUserActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminUserNotifier extends Notifier<AdminUserActionState> {
  @override
  AdminUserActionState build() {
    return const AdminUserActionState();
  }

  Future<bool> createUser(String universityId, String pin, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(adminUserRepositoryProvider);
      await repo.createUser(
        universityId: universityId,
        pin: pin,
        role: role,
      );
      ref.invalidate(adminUserListProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(adminUserRepositoryProvider);
      await repo.deleteUser(userId);
      ref.invalidate(adminUserListProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> importUsersCsv(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(adminUserRepositoryProvider);
      final result = await repo.importUsersCsv(filePath);
      ref.invalidate(adminUserListProvider);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final adminUserNotifierProvider = NotifierProvider<AdminUserNotifier, AdminUserActionState>(() {
  return AdminUserNotifier();
});
