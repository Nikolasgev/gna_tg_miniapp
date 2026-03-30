import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.businessId,
    required this.name,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        position,
        createdAt,
        updatedAt,
      ];
}

