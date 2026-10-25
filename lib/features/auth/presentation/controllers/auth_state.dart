import '../../domain/entities/user_profile.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  authenticated,
  needsProfileCompletion,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? email;
  final UserProfile? userProfile;
  final String? errorMessage;
  final int? remainingAttempts;

  const AuthState({
    this.status = AuthStatus.initial,
    this.email,
    this.userProfile,
    this.errorMessage,
    this.remainingAttempts,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdult => userProfile?.isAdult ?? false;

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    UserProfile? userProfile,
    String? errorMessage,
    int? remainingAttempts,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
    );
  }
}
