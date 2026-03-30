import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/admin_panel/domain/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository settingsRepository;

  SettingsBloc({required this.settingsRepository}) : super(SettingsInitial()) {
    logger.i('SettingsBloc created');

    on<LoadSettings>(_onLoadSettings);
    on<UpdateSettings>(_onUpdateSettings);
    on<UploadLogo>(_onUploadLogo);
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    logger.i('LoadSettings event: businessSlug=${event.businessSlug}');
    emit(SettingsLoading());

    final result = await settingsRepository.getSettings(businessSlug: event.businessSlug);

    result.fold(
      (failure) {
        logger.e('Failed to load settings: ${failure.message}');
        emit(SettingsError(failure.message));
      },
      (settings) {
        logger.i('Settings loaded');
        emit(SettingsLoaded(settings));
      },
    );
  }

  void _onUpdateSettings(UpdateSettings event, Emitter<SettingsState> emit) async {
    logger.i('UpdateSettings event');
    emit(SettingsSaving());

    final result = await settingsRepository.updateSettings(
      businessSlug: event.businessSlug,
      settingsData: event.settingsData,
    );

    result.fold(
      (failure) {
        logger.e('Failed to update settings: ${failure.message}');
        emit(SettingsError(failure.message));
      },
      (settings) {
        logger.i('Settings updated');
        emit(SettingsUpdated(settings));
      },
    );
  }

  void _onUploadLogo(UploadLogo event, Emitter<SettingsState> emit) async {
    logger.i('UploadLogo event: fileName=${event.fileName}');
    emit(LogoUploading());

    final result = await settingsRepository.uploadImage(
      imageBytes: event.imageBytes,
      fileName: event.fileName,
    );

    result.fold(
      (failure) {
        logger.e('Failed to upload logo: ${failure.message}');
        emit(LogoUploadError(failure.message));
      },
      (imageUrl) {
        logger.i('Logo uploaded: $imageUrl');
        emit(LogoUploaded(imageUrl));
      },
    );
  }
}

