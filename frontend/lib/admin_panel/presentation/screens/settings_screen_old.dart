import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/utils/logger.dart' show logger;

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
  final ApiClient _apiClient = ApiClient();
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
  
  bool _isLoading = false;
  bool _supportsDelivery = false;
  bool _supportsPickup = true;
  List<String> _paymentMethods = ['cash'];
  PlatformFile? _selectedLogoFile;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
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
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.businessSettings(widget.businessSlug),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
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
          _selectedLogoFile = null; // Очищаем выбранный файл при загрузке
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки настроек: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Загружаем логотип, если выбран файл
      String? logoUrl = _logoController.text.isEmpty ? null : _logoController.text;
      if (_selectedLogoFile != null) {
        final uploadedUrl = await _uploadLogo();
        if (uploadedUrl != null) {
          logoUrl = uploadedUrl;
        } else {
          // Если загрузка не удалась, не продолжаем
          setState(() {
            _isLoading = false;
          });
          return;
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
      
      final response = await _apiClient.dio.put(
        ApiConstants.businessSettings(widget.businessSlug),
        data: data,
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          // Обновляем поле логотипа с загруженным URL
          if (logoUrl != null) {
            _logoController.text = logoUrl;
          }
          setState(() {
            _selectedLogoFile = null; // Очищаем выбранный файл после сохранения
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Настройки сохранены'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _pickLogo() async {
    if (kIsWeb) {
      // Для веба используем HTML input элемент напрямую
      await _pickLogoWeb();
    } else {
      // Для других платформ используем FilePicker
      await _pickLogoNative();
    }
  }

  Future<void> _pickLogoWeb() async {
    if (!kIsWeb) {
      return;
    }
    
    try {
      // Для веба используем dart:html напрямую через условный импорт
      // ignore: undefined_prefixed_name
      final input = platform.FileUploadInputElement()
        ..accept = 'image/*'
        ..multiple = false;
      
      input.click();
      
      // Ждем выбора файла
      await input.onChange.first;
      
      if (input.files != null && input.files!.isNotEmpty) {
        final htmlFile = input.files!.first;
        
        // Читаем файл как bytes
        // ignore: undefined_prefixed_name
        final reader = platform.FileReader();
        reader.readAsArrayBuffer(htmlFile);
        await reader.onLoadEnd.first;
        
        final bytes = reader.result as Uint8List?;
        
        if (bytes != null) {
          // Создаем PlatformFile из данных
          final platformFile = PlatformFile(
            name: htmlFile.name,
            size: htmlFile.size,
            bytes: bytes,
          );
          
          setState(() {
            _selectedLogoFile = platformFile;
            // Очищаем поле URL при выборе файла
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
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Не удалось прочитать файл'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      logger.d('❌ Error in _pickLogoWeb: $e');
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
            // Очищаем поле URL при выборе файла
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
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Не удалось получить данные файла'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      logger.d('❌ Error in _pickLogoNative: $e');
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

  Future<String?> _uploadLogo() async {
    if (_selectedLogoFile == null) {
      return null;
    }

    try {
      final fileName = _selectedLogoFile!.name;
      Uint8List? fileBytes;
      
      // Для веб используем bytes напрямую, для других платформ - путь к файлу
      if (_selectedLogoFile!.bytes != null) {
        // Flutter Web или файл уже загружен в память - используем bytes
        fileBytes = _selectedLogoFile!.bytes;
      } else if (_selectedLogoFile!.path != null && !kIsWeb) {
        // Другие платформы (не веб) - читаем файл с диска
        // Для веба этот путь не используется, так как bytes уже доступны
        throw Exception('Для веб-платформы файл должен содержать bytes. Используйте _pickLogoWeb().');
      } else {
        throw Exception('Не удалось получить данные файла. Файл не содержит ни bytes, ни path.');
      }
      
      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception('Файл пуст или не удалось получить данные');
      }
      
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        ApiConstants.uploadImage,
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final imageUrl = data['url'] as String;
        
        // Преобразуем относительный URL в абсолютный
        final baseUrl = _apiClient.dio.options.baseUrl;
        if (imageUrl.startsWith('/')) {
          return '$baseUrl$imageUrl';
        }
        return imageUrl;
      } else {
        throw Exception('Ошибка загрузки: статус ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки изображения: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: _isLoading && _nameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Основная информация
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
                  
                  // UI настройки
                  _buildSectionTitle('Внешний вид'),
                  // Загрузка логотипа
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
                            // При вводе URL очищаем выбранный файл
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
                  
                  // Настройки доставки
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
                  
                  // Способы оплаты
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
                  
                  // Настройки YooKassa
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
                  
                  // Кнопка сохранения
                  FilledButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
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

