// Turns HTTP 426 / 503 into app-wide "force update" / "maintenance" signals.
//
// Source: corsa-customer lib/core/services/api_service.dart (426 → force update,
//         503 → maintenance, handed to the system gate above the router).
import 'package:dio/dio.dart';

enum AppStatusSignal { upgradeRequired, maintenance }

class AppStatusInterceptor extends Interceptor {
  AppStatusInterceptor({required this.onSignal});

  final void Function(AppStatusSignal signal, String? message) onSignal;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (status == 426 || status == 503) {
      final body = err.response?.data;
      final message = body is Map && body['message'] is String ? body['message'] as String : null;
      onSignal(status == 426 ? AppStatusSignal.upgradeRequired : AppStatusSignal.maintenance, message);
    }
    handler.next(err);
  }
}
