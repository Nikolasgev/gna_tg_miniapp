import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/admin_panel/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final ApiClient _apiClient;

  OrdersRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getOrders({
    required String businessSlug,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      final response = await _apiClient.dio.get(
        ApiConstants.businessOrders(businessSlug),
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return Right(data.cast<Map<String, dynamic>>());
      }

      return Left(ServerFailure('Ошибка загрузки заказов: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка загрузки заказов',
        error: e,
      );
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('Не удалось подключиться к серверу'));
      }
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Бизнес не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки заказов: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка загрузки заказов',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка загрузки заказов: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getOrder({
    required String businessSlug,
    required String orderId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.order(orderId),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        return Left(const NotFoundFailure('Заказ не найден'));
      }

      return Left(ServerFailure('Ошибка загрузки заказа: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка загрузки заказа',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Заказ не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки заказа: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка загрузки заказа',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка загрузки заказа: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateOrderStatus({
    required String businessSlug,
    required String orderId,
    required String status,
    String? paymentStatus,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      // Добавляем статус только если он не пустой
      if (status.isNotEmpty) {
        data['status'] = status;
      }
      
      // Добавляем статус оплаты если он указан
      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        data['payment_status'] = paymentStatus;
      }
      
      // Проверяем что хотя бы один статус указан
      if (data.isEmpty) {
        return Left(ServerFailure('Необходимо указать хотя бы один статус для обновления'));
      }

      final response = await _apiClient.dio.patch(
        ApiConstants.updateOrderStatus(orderId),
        data: data,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        return Left(const NotFoundFailure('Заказ не найден'));
      }

      return Left(ServerFailure('Ошибка обновления статуса заказа: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка обновления статуса заказа',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Заказ не найден'));
      }
      return Left(ServerFailure('Ошибка обновления статуса заказа: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка обновления статуса заказа',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка обновления статуса заказа: $e'));
    }
  }
}

