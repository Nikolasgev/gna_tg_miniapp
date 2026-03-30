part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class ValidateInitData extends AuthEvent {
  final String initData;
  final String businessSlug;

  const ValidateInitData({
    required this.initData,
    required this.businessSlug,
  });

  @override
  List<Object> get props => [initData, businessSlug];
}

