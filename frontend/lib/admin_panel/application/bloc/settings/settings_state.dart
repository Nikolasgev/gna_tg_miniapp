part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final Map<String, dynamic> settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsSaving extends SettingsState {}

class SettingsUpdated extends SettingsState {
  final Map<String, dynamic> settings;

  const SettingsUpdated(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Состояния для загрузки логотипа
class LogoUploading extends SettingsState {}

class LogoUploaded extends SettingsState {
  final String imageUrl;

  const LogoUploaded(this.imageUrl);

  @override
  List<Object?> get props => [imageUrl];
}

class LogoUploadError extends SettingsState {
  final String message;

  const LogoUploadError(this.message);

  @override
  List<Object?> get props => [message];
}

