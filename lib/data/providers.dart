import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final restaurantIdProvider = Provider<String>((ref) => kRestaurantId);
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(ref.watch(restaurantIdProvider)),
);

/// Trạng thái đăng nhập Firebase
final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});
