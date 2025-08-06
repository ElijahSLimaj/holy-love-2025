part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Event that is triggered when the user changes (logged in/out)
final class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final AuthUser user;

  @override
  List<Object> get props => [user];
}

/// Event to trigger Google sign in
final class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

/// Event to trigger email sign in
final class AuthSignInWithEmailRequested extends AuthEvent {
  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// Event to trigger email sign up
final class AuthSignUpWithEmailRequested extends AuthEvent {
  const AuthSignUpWithEmailRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// Event to trigger sign out
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event to refresh the current user's profile completion status
final class AuthRefreshUserRequested extends AuthEvent {
  const AuthRefreshUserRequested();
}