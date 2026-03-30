import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tg_store/admin_panel/application/bloc/categories/categories_bloc.dart';
import 'package:tg_store/admin_panel/data/repositories/categories_repository_impl.dart';
import 'package:tg_store/admin_panel/presentation/screens/category_products_screen.dart';

class CategoriesScreen extends StatelessWidget {
  final String businessSlug;

  const CategoriesScreen({
    super.key,
    required this.businessSlug,
  });

  Future<void> _createCategory(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCategoryScreen(
          businessSlug: businessSlug,
        ),
      ),
    );

    if (result == true) {
      context.read<CategoriesBloc>().add(LoadCategories(businessSlug));
    }
  }

  Future<void> _editCategory(BuildContext context, Map<String, dynamic> category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCategoryScreen(
          businessSlug: businessSlug,
          category: category,
        ),
      ),
    );

    if (result == true) {
      context.read<CategoriesBloc>().add(LoadCategories(businessSlug));
    }
  }

  Future<void> _deleteCategory(BuildContext context, Map<String, dynamic> category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text('Вы уверены, что хотите удалить "${category['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<CategoriesBloc>().add(DeleteCategory(businessSlug, category['id']));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoriesBloc(
        categoriesRepository: CategoriesRepositoryImpl(),
      )..add(LoadCategories(businessSlug)),
      child: BlocListener<CategoriesBloc, CategoriesState>(
        listener: (context, state) {
          if (state is CategoryDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Категория удалена'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (state is CategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Произошла ошибка. Попробуйте еще раз.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            if (state is CategoriesLoading) {
              return Scaffold(
                appBar: AppBar(title: const Text('Категории')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (state is CategoriesError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Категории')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Не удалось загрузить категории. Попробуйте еще раз.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<CategoriesBloc>().add(LoadCategories(businessSlug));
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final categories = state is CategoriesLoaded 
                ? state.categories.cast<Map<String, dynamic>>()
                : <Map<String, dynamic>>[];

            return Scaffold(
              appBar: AppBar(
                title: const Text('Категории'),
              ),
              body: categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined, 
                            size: 64, 
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text('Нет категорий'),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите + чтобы добавить первую категорию',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        context.read<CategoriesBloc>().add(LoadCategories(businessSlug));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${category['position'] ?? 0}'),
                              ),
                              title: Text(category['name'] ?? 'Без названия'),
                              subtitle: category['surcharge'] != null && (category['surcharge'] as num) > 0
                                  ? Text(
                                      'Доплата: ${category['surcharge']} ₽',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryProductsScreen(
                                      businessSlug: businessSlug,
                                      category: category,
                                    ),
                                  ),
                                );
                              },
                              trailing: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _editCategory(context, category),
                                      tooltip: 'Редактировать',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete, 
                                        color: Theme.of(context).colorScheme.error, 
                                        size: 20,
                                      ),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _deleteCategory(context, category),
                                      tooltip: 'Удалить',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _createCategory(context),
                child: const Icon(Icons.add),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CreateCategoryScreen extends StatefulWidget {
  final String businessSlug;
  final Map<String, dynamic>? category;

  const CreateCategoryScreen({
    super.key,
    required this.businessSlug,
    this.category,
  });

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController(text: '0');
  final _surchargeController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!['name'] ?? '';
      _positionController.text = (widget.category!['position'] ?? 0).toString();
      _surchargeController.text = (widget.category!['surcharge'] ?? 0).toString();
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = {
      'name': _nameController.text,
      'position': int.tryParse(_positionController.text) ?? 0,
      'surcharge': double.tryParse(_surchargeController.text) ?? 0.0,
    };

    final bloc = context.read<CategoriesBloc>();

    if (widget.category != null) {
      bloc.add(UpdateCategory(widget.businessSlug, widget.category!['id'], data));
    } else {
      bloc.add(CreateCategory(widget.businessSlug, data));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _surchargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoriesBloc(
        categoriesRepository: CategoriesRepositoryImpl(),
      ),
      child: BlocListener<CategoriesBloc, CategoriesState>(
        listener: (context, state) {
          if (state is CategoryCreated || state is CategoryUpdated) {
            Navigator.pop(context, true);
          } else if (state is CategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Произошла ошибка. Попробуйте еще раз.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            final isLoading = state is CategorySaving;
            
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.category != null ? 'Редактировать категорию' : 'Новая категория'),
              ),
              body: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название *',
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
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Позиция (порядок сортировки)',
                        border: OutlineInputBorder(),
                        helperText: 'Меньшее число = выше в списке',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _surchargeController,
                      decoration: const InputDecoration(
                        labelText: 'Доплата за категорию',
                        border: OutlineInputBorder(),
                        helperText: 'Дополнительная плата за товары этой категории',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final num = double.tryParse(value);
                          if (num == null || num < 0) {
                            return 'Введите неотрицательное число';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _submit(context),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : Text(widget.category != null ? 'Сохранить изменения' : 'Создать категорию'),
                          ),
                        ),
                      ),
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
}

