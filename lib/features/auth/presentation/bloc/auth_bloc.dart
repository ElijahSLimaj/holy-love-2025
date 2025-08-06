import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    on<_AuthUserChanged>(_onAuthUserChanged);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<AuthSignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthRefreshUserRequested>(_onRefreshUserRequested);
    
    _userSubscription = _authRepository.user.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  final AuthRepository _authRepository;
  late final StreamSubscription<AuthUser> _userSubscription;

  void _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    emit(
      event.user.isNotEmpty
          ? AuthState.authenticated(event.user)
          : const AuthState.unauthenticated(),
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    try {
      await _authRepository.signInWithGoogle();
      // Don't emit here - the user stream will handle it
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    try {
      await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      // Don't emit here - the user stream will handle it
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSignUpWithEmailRequested(
    AuthSignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    try {
      await _authRepository.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      // Don't emit here - the user stream will handle it
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshUserRequested(
    AuthRefreshUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final refreshedUser = await _authRepository.refreshCurrentUser();
      emit(AuthState.authenticated(refreshedUser));
    } catch (error) {
      emit(
        state.copyWith(
          errorMessage: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}