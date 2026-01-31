import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:messenger_clone/common/services/network_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OTPEmailService {
  const OTPEmailService._();

  static const int _maxAttempts = 5;
  static const Duration _otpExpiry = Duration(minutes: 5);
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> sendOTPEmail(String email, String otp) async {
    return NetworkUtils.withNetworkCheck(() async {
      final expiry = DateTime.now().add(_otpExpiry);
      debugPrint("otp: $otp");
      final smtpServer = gmail('nguyen902993@gmail.com', 'lqpn cxdp tlti blhv');

      try {
        await _supabase.from('otps').insert({
          'email': email,
          'otp': otp,
          'expiry': expiry.toIso8601String(),
          'attempts': 0,
        });
      } catch (e) {
        // If table doesn't exist or error, generic log.
        // Might need 'otps' table in Supabase.
        debugPrint('Failed to save OTP to DB: $e');
      }

      final message =
          Message()
            ..from = Address('nguyen902993@gmail.com', 'Messenger Clone')
            ..recipients.add(email)
            ..subject = 'Mã OTP xác thực'
            ..text =
                'Messenger Clone đã cho bạn mã OTP: $otp (hiệu lực 5 phút). \nCảm ơn bạn đã sử dụng dịch vụ của chúng tôi.';

      try {
        final sendOTP = await send(message, smtpServer);
        debugPrint("Message Sent : $sendOTP");
      } on MailerException catch (e) {
        debugPrint('Gửi OTP thất bại: $e');
      }
    });
  }

  static Future<bool> verifyOTP(String email, String userInput) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response =
            await _supabase
                .from('otps')
                .select()
                .eq('email', email)
                .order('expiry', ascending: false)
                .limit(1)
                .maybeSingle();

        if (response == null) return false;

        final docId = response['id'] ?? response['\$id'];
        final attempts = response['attempts'] ?? 0;
        final expiryStr = response['expiry'] as String;

        if (attempts >= _maxAttempts) {
          await _deleteOTP(docId);
          throw Exception('Vượt quá số lần thử');
        }

        if (DateTime.parse(expiryStr).isBefore(DateTime.now())) {
          await _deleteOTP(docId);
          return false;
        }

        if (response['otp'] != userInput) {
          await _increaseAttemptCount(docId, attempts);
          return false;
        }

        await _deleteOTP(docId);
        return true;
      } catch (e) {
        debugPrint('Verify OTP error: $e');
        return false;
      }
    });
  }

  static Future<void> _increaseAttemptCount(
    dynamic documentId,
    int currentAttempts,
  ) async {
    await _supabase
        .from('otps')
        .update({'attempts': currentAttempts + 1})
        .eq('id', documentId);
  }

  static Future<void> _deleteOTP(dynamic documentId) async {
    await _supabase.from('otps').delete().eq('id', documentId);
  }

  static Future<num> getRemainingAttempts(String email) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response =
            await _supabase
                .from('otps')
                .select()
                .eq('email', email)
                .order('expiry', ascending: false)
                .limit(1)
                .maybeSingle();

        if (response == null) return _maxAttempts;

        final usedAttempts = response['attempts'] ?? 0;
        return _maxAttempts - usedAttempts;
      } catch (e) {
        debugPrint('Lỗi khi lấy số lần thử: $e');
        return _maxAttempts;
      }
    });
  }

  static String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
}
