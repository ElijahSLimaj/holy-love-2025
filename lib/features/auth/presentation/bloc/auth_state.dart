part of 'auth_bloc.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
}

final class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.user = AuthUser.empty,
    this.errorMessage,
  });

  /// Unknown authentication state.
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  /// Authenticated state with user data.
  const AuthState.authenticated(AuthUser user)
      : this._(status: AuthStatus.authenticated, user: user);

  /// Unauthenticated state.
  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  /// Loading state during authentication operations.
  const AuthState.loading() : this._(status: AuthStatus.loading);

  /// The current authentication status.
  final AuthStatus status;

  /// The current user. Defaults to [AuthUser.empty].
  final AuthUser user;

  /// Optional error message for failed operations.
  final String? errorMessage;

  @override
  List<Object?> get props => [status, user, errorMessage];

  /// Creates a copy of the current [AuthState] with optional new values.
  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
  }) {
    return AuthState._(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
