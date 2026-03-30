import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tg_store/admin_panel/application/bloc/settings/settings_bloc.dart';
import 'package:tg_store/admin_panel/data/repositories/settings_repository_impl.dart';

// Условные импорты для веба и нативных платформ
import 'dart:html' if (dart.library.io) 'dart:io' as platform;

class SettingsScreen extends StatefulWidget {
  final String businessSlug;

  const SettingsScreen({
    super.key,
    required this.businessSlug,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers для основных полей
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _currencyController = TextEditingController();
  final _timezoneController = TextEditingController();
  
  // Controllers для UI настроек
  final _logoController = TextEditingController();
  final _primaryColorController = TextEditingController();
  final _backgroundColorController = TextEditingController();
  final _textColorController = TextEditingController();
  
  // Controllers для YooKassa
  final _yookassaShopIdController = TextEditingController();
  final _yookassaSecretKeyController = TextEditingController();
  
  bool _supportsDelivery = false;
  bool _supportsPickup = true;
  List<String> _paymentMethods = ['cash'];
  PlatformFile? _selectedLogoFile;
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _currencyController.dispose();
    _timezoneController.dispose();
    _logoController.dispose();
    _primaryColorController.dispose();
    _backgroundColorController.dispose();
    _textColorController.dispose();
    _yookassaShopIdController.dispose();
    _yookassaSecretKeyController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _currencyController.text = data['currency'] ?? 'RUB';
    _timezoneController.text = data['timezone'] ?? '';
    _logoController.text = data['logo'] ?? '';
    _primaryColorController.text = data['primary_color'] ?? '';
    _backgroundColorController.text = data['background_color'] ?? '';
    _textColorController.text = data['text_color'] ?? '';
    _supportsDelivery = data['supports_delivery'] ?? false;
    _supportsPickup = data['supports_pickup'] ?? true;
    _paymentMethods = List<String>.from(data['payment_methods'] ?? ['cash']);
    _yookassaShopIdController.text = data['yookassa_shop_id'] ?? '';
    _yookassaSecretKeyController.text = data['yookassa_secret_key'] ?? '';
    _selectedLogoFile = null;
  }
  
  Future<void> _saveSettings(SettingsBloc bloc) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Загружаем логотип, если выбран файл
    String? logoUrl = _logoController.text.isEmpty ? null : _logoController.text;
    if (_selectedLogoFile != null) {
      final bytes = _selectedLogoFile!.bytes;
      if (bytes != null) {
        bloc.add(UploadLogo(bytes, _selectedLogoFile!.name));
        // Ждем загрузки логотипа
        await bloc.stream.firstWhere(
          (state) => state is LogoUploaded || state is LogoUploadError,
        );
        
        if (bloc.state is LogoUploaded) {
          logoUrl = (bloc.state as LogoUploaded).imageUrl;
          _logoController.text = logoUrl;
        } else if (bloc.state is LogoUploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((bloc.state as LogoUploadError).message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }
      }
    }
    
    final data = <String, dynamic>{
      'name': _nameController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'currency': _currencyController.text,
      'timezone': _timezoneController.text.isEmpty ? null : _timezoneController.text,
      'logo': logoUrl,
      'primary_color': _primaryColorController.text.isEmpty ? null : _primaryColorController.text,
      'background_color': _backgroundColorController.text.isEmpty ? null : _backgroundColorController.text,
      'text_color': _textColorController.text.isEmpty ? null : _textColorController.text,
      'supports_delivery': _supportsDelivery,
      'supports_pickup': _supportsPickup,
      'payment_methods': _paymentMethods,
      'yookassa_shop_id': _yookassaShopIdController.text.isEmpty ? null : _yookassaShopIdController.text,
      'yookassa_secret_key': _yookassaSecretKeyController.text.isEmpty ? null : _yookassaSecretKeyController.text,
    };
    
    bloc.add(UpdateSettings(widget.businessSlug, data));
  }
  
  Future<void> _pickLogo() async {
    if (kIsWeb) {
      await _pickLogoWeb();
    } else {
      await _pickLogoNative();
    }
  }

  Future<void> _pickLogoWeb() async {
    if (!kIsWeb) return;
    
    try {
      // ignore: undefined_prefixed_name
      final input = platform.FileUploadInputElement()
        ..accept = 'image/*'
        ..multiple = false;
      
      input.click();
      await input.onChange.first;
      
      if (input.files != null && input.files!.isNotEmpty) {
        final htmlFile = input.files!.first;
        
        // ignore: undefined_prefixed_name
        final reader = platform.FileReader();
        reader.readAsArrayBuffer(htmlFile);
        await reader.onLoadEnd.first;
        
        final bytes = reader.result as Uint8List?;
        
        if (bytes != null) {
          setState(() {
            _selectedLogoFile = PlatformFile(
              name: htmlFile.name,
              size: htmlFile.size,
              bytes: bytes,
            );
            _logoController.clear();
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Файл выбран: ${htmlFile.name}'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора файла: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickLogoNative() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        if (file.path != null || file.bytes != null) {
          setState(() {
            _selectedLogoFile = file;
            _logoController.clear();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Файл выбран: ${file.name}'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора файла: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(
        settingsRepository: SettingsRepositoryImpl(),
      )..add(LoadSettings(widget.businessSlug)),
      child: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded) {
            _populateControllers(state.settings);
          } else if (state is SettingsUpdated) {
            _populateControllers(state.settings);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Настройки сохранены'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final isLoading = state is SettingsLoading || state is SettingsSaving || state is LogoUploading;
            final canSave = !isLoading && state is SettingsLoaded;
            
            return Scaffold(
              appBar: AppBar(
                title: const Text('Настройки'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: canSave ? () => _saveSettings(context.read<SettingsBloc>()) : null,
                    tooltip: 'Сохранить',
                  ),
                ],
              ),
              body: isLoading && _nameController.text.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSectionTitle('Основная информация'),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Название бизнеса *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите название';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Описание',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _currencyController,
                            decoration: const InputDecoration(
                              labelText: 'Валюта *',
                              border: OutlineInputBorder(),
                              helperText: 'Например: RUB, USD, EUR',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите валюту';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _timezoneController,
                            decoration: const InputDecoration(
                              labelText: 'Часовой пояс',
                              border: OutlineInputBorder(),
                              helperText: 'Например: Europe/Moscow',
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          _buildSectionTitle('Внешний вид'),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _logoController,
                                  decoration: const InputDecoration(
                                    labelText: 'URL логотипа',
                                    border: OutlineInputBorder(),
                                    hintText: 'Или загрузите файл',
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && _selectedLogoFile != null) {
                                      setState(() {
                                        _selectedLogoFile = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Загрузить'),
                              ),
                            ],
                          ),
                          if (_selectedLogoFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.image, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedLogoFile!.name,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _selectedLogoFile = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _primaryColorController,
                            decoration: const InputDecoration(
                              labelText: 'Основной цвет',
                              border: OutlineInputBorder(),
                              helperText: 'Hex код цвета (например: #FF5722)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _backgroundColorController,
                            decoration: const InputDecoration(
                              labelText: 'Цвет фона',
                              border: OutlineInputBorder(),
                              helperText: 'Hex код цвета',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _textColorController,
                            decoration: const InputDecoration(
                              labelText: 'Цвет текста',
                              border: OutlineInputBorder(),
                              helperText: 'Hex код цвета',
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          _buildSectionTitle('Доставка и получение'),
                          SwitchListTile(
                            title: const Text('Поддержка доставки'),
                            subtitle: const Text('Клиенты смогут заказать доставку'),
                            value: _supportsDelivery,
                            onChanged: (value) {
                              setState(() {
                                _supportsDelivery = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Поддержка самовывоза'),
                            subtitle: const Text('Клиенты смогут забрать заказ сами'),
                            value: _supportsPickup,
                            onChanged: (value) {
                              setState(() {
                                _supportsPickup = value;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          _buildSectionTitle('Способы оплаты'),
                          CheckboxListTile(
                            title: const Text('Наличными'),
                            value: _paymentMethods.contains('cash'),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  if (!_paymentMethods.contains('cash')) {
                                    _paymentMethods.add('cash');
                                  }
                                } else {
                                  _paymentMethods.remove('cash');
                                }
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Онлайн (YooKassa)'),
                            value: _paymentMethods.contains('online'),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  if (!_paymentMethods.contains('online')) {
                                    _paymentMethods.add('online');
                                  }
                                } else {
                                  _paymentMethods.remove('online');
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          if (_paymentMethods.contains('online')) ...[
                            _buildSectionTitle('Настройки YooKassa'),
                            TextFormField(
                              controller: _yookassaShopIdController,
                              decoration: const InputDecoration(
                                labelText: 'Shop ID',
                                border: OutlineInputBorder(),
                                helperText: 'ID магазина в YooKassa',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _yookassaSecretKeyController,
                              decoration: const InputDecoration(
                                labelText: 'Secret Key',
                                border: OutlineInputBorder(),
                                helperText: 'Секретный ключ YooKassa',
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          FilledButton(
                            onPressed: canSave ? () => _saveSettings(context.read<SettingsBloc>()) : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Сохранить настройки'),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

