part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  final String businessSlug;

  const LoadSettings(this.businessSlug);

  @override
  List<Object?> get props => [businessSlug];
}

class UpdateSettings extends SettingsEvent {
  final String businessSlug;
  final Map<String, dynamic> settingsData;

  const UpdateSettings(this.businessSlug, this.settingsData);

  @override
  List<Object?> get props => [businessSlug, settingsData];
}

class UploadLogo extends SettingsEvent {
  final List<int> imageBytes;
  final String fileName;

  const UploadLogo(this.imageBytes, this.fileName);

  @override
  List<Object?> get props => [imageBytes, fileName];
}

