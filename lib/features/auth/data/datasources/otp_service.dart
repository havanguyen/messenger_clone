import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:messenger_clone/core/network/network_utils.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class OTPEmailService {
  const OTPEmailService._();

  static const int _maxAttempts = 5;
  static const Duration _otpExpiry = Duration(minutes: 5);
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> sendOTPEmail(String email, String otp) async {
    return NetworkUtils.withNetworkCheck(() async {
      final expiry = DateTime.now().add(_otpExpiry);
      debugPrint("otp: $otp");
      final smtpServer = gmail(dotenv.env['EMAIL_OTP']!, dotenv.env['APP_PW']!);

      try {
        await _firestore.collection('otps').add({
          'email': email,
          'otp': otp,
          'expiry': expiry.toIso8601String(),
          'attempts': 0,
        });
      } catch (e) {
        debugPrint('Failed to save OTP to DB: $e');
      }

      final message =
          Message()
            ..from = Address(dotenv.env['EMAIL_OTP']!, 'Messenger Clone')
            ..recipients.add(email)
            ..subject = 'OTP Verification Code'
            ..text =
                'Messenger Clone has sent you an OTP code: $otp (valid for 5 minutes). \nThank you for using our service.';

      try {
        final sendOTP = await send(message, smtpServer);
        debugPrint("Message Sent : $sendOTP");
      } on MailerException catch (e) {
        debugPrint('Failed to send OTP: $e');
      }
    });
  }

  static Future<bool> verifyOTP(String email, String userInput) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final querySnapshot =
            await _firestore
                .collection('otps')
                .where('email', isEqualTo: email)
                .orderBy('expiry', descending: true)
                .limit(1)
                .get();

        if (querySnapshot.docs.isEmpty) return false;

        final response = querySnapshot.docs.first.data();
        response['id'] = querySnapshot.docs.first.id;

        final docId = response['id'] ?? response['\$id'];
        final attempts = response['attempts'] ?? 0;
        final expiryStr = response['expiry'] as String;

        if (attempts >= _maxAttempts) {
          await _deleteOTP(docId);
          throw Exception('Exceeded maximum attempts');
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
    await _firestore.collection('otps').doc(documentId).update({
      'attempts': currentAttempts + 1,
    });
  }

  static Future<void> _deleteOTP(dynamic documentId) async {
    await _firestore.collection('otps').doc(documentId).delete();
  }

  static Future<num> getRemainingAttempts(String email) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final querySnapshot =
            await _firestore
                .collection('otps')
                .where('email', isEqualTo: email)
                .orderBy('expiry', descending: true)
                .limit(1)
                .get();

        if (querySnapshot.docs.isEmpty) return _maxAttempts;

        final response = querySnapshot.docs.first.data();

        final usedAttempts = response['attempts'] ?? 0;
        return _maxAttempts - usedAttempts;
      } catch (e) {
        debugPrint('Error getting remaining attempts: $e');
        return _maxAttempts;
      }
    });
  }

  static String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
}
