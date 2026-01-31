import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NetworkUtils {
  static const Duration _defaultConnectionCheckTimeout = Duration(seconds: 3);
  static const Duration _defaultApiCallTimeout = Duration(seconds: 30);

  static Future<bool> _checkInternetConnection() async {
    try {
      final endpoints = [
        Uri.parse('https://www.google.com'),
        Uri.parse('https://www.cloudflare.com'),
        Uri.parse('https://www.apple.com'),
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await http
              .head(endpoint)
              .timeout(_defaultConnectionCheckTimeout);

          if (kDebugMode) {
            debugPrint(
              'Network check to ${endpoint.host} - '
              'Status: ${response.statusCode}',
            );
          }

          if (response.statusCode >= 200 && response.statusCode < 300) {
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Connection check failed for ${endpoint.host}: $e');
          }
          continue;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Global connection check error: $e');
      }
      return false;
    }
  }

  static Future<T> withNetworkCheck<T>(
    Future<T> Function() apiCall, {
    Duration? timeout,
    bool retryOnFailure = false,
    int maxRetries = 2,
  }) async {
    int attempt = 0;
    late Exception lastException;

    while (attempt <= maxRetries) {
      attempt++;
      try {
        if (!await _checkInternetConnection()) {
          throw const SocketException('No internet connection available');
        }

        return await apiCall().timeout(
          timeout ?? _defaultApiCallTimeout,
          onTimeout:
              () =>
                  throw TimeoutException(
                    'API call timed out after ${timeout ?? _defaultApiCallTimeout}',
                  ),
        );
      } on SocketException catch (e) {
        lastException = e;
        if (kDebugMode) {
          debugPrint('Network error: ${e.message}');
        }
        if (!retryOnFailure || attempt >= maxRetries) {
          throw Exception('Network error: ${e.message}');
        }
      } on TimeoutException catch (e) {
        lastException = e;
        if (kDebugMode) {
          debugPrint('Timeout error: ${e.message}');
        }
        if (!retryOnFailure || attempt >= maxRetries) {
          throw Exception('Request timeout: ${e.message}');
        }
      } on http.ClientException catch (e) {
        lastException = e;
        if (kDebugMode) {
          debugPrint('HTTP client error: ${e.message}');
        }
        if (!retryOnFailure || attempt >= maxRetries) {
          throw Exception('HTTP error: ${e.message}');
        }
      } catch (e) {
        lastException = Exception('Unexpected error: $e');
        if (kDebugMode) {
          debugPrint('Unexpected error: $e');
        }
        if (!retryOnFailure || attempt >= maxRetries) {
          throw lastException;
        }
      }
      if (retryOnFailure && attempt < maxRetries) {
        final delay = Duration(seconds: attempt * 2);
        if (kDebugMode) {
          debugPrint('Retrying in ${delay.inSeconds} seconds...');
        }
        await Future.delayed(delay);
      }
    }

    throw lastException;
  }

  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException;
  }
}
