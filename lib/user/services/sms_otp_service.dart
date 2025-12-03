import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// SMS OTP Service using iprogsms.com API
/// 
/// Note: The API endpoint and request format may need to be adjusted
/// based on the actual iprogsms.com API documentation.
/// Common formats include:
/// - POST with JSON body
/// - GET with query parameters
/// - POST with form data
class SmsOtpService {
  static const String _apiKey = '8c8f3d3e9083bc928b1e5cf47c898f6b0fdfb5e4';
  // Correct API endpoint based on iprogsms.com documentation
  static const String _baseUrl = 'https://www.iprogsms.com/api/v1';
  
  // Storage keys for SharedPreferences
  static const String _otpStorageKey = 'otp_storage';
  static const String _otpExpiryKey = 'otp_expiry';
  
  // In-memory cache for faster access (synced with SharedPreferences)
  static final Map<String, String> _otpStorageCache = {};
  static final Map<String, DateTime> _otpExpiryCache = {};
  static bool _cacheInitialized = false;
  
  /// Initialize cache from SharedPreferences
  static Future<void> _initializeCache() async {
    if (_cacheInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final otpStorageJson = prefs.getString(_otpStorageKey);
      final otpExpiryJson = prefs.getString(_otpExpiryKey);
      
      if (otpStorageJson != null) {
        final storageMap = jsonDecode(otpStorageJson) as Map<String, dynamic>;
        _otpStorageCache.clear();
        storageMap.forEach((key, value) {
          _otpStorageCache[key] = value.toString();
        });
      }
      
      if (otpExpiryJson != null) {
        final expiryMap = jsonDecode(otpExpiryJson) as Map<String, dynamic>;
        _otpExpiryCache.clear();
        expiryMap.forEach((key, value) {
          final timestamp = value as int;
          _otpExpiryCache[key] = DateTime.fromMillisecondsSinceEpoch(timestamp);
        });
      }
      
      // Clear expired OTPs on initialization
      _clearExpiredOtps();
      _cacheInitialized = true;
    } catch (e) {
      print('Error initializing OTP cache: $e');
      _cacheInitialized = true; // Mark as initialized to prevent retry loops
    }
  }
  
  /// Save OTP storage to SharedPreferences
  static Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert maps to JSON
      final otpStorageJson = jsonEncode(_otpStorageCache);
      final otpExpiryMap = <String, int>{};
      _otpExpiryCache.forEach((key, value) {
        otpExpiryMap[key] = value.millisecondsSinceEpoch;
      });
      final otpExpiryJson = jsonEncode(otpExpiryMap);
      
      await prefs.setString(_otpStorageKey, otpStorageJson);
      await prefs.setString(_otpExpiryKey, otpExpiryJson);
    } catch (e) {
      print('Error saving OTP to storage: $e');
    }
  }
  
  /// Generate a 6-digit OTP
  static String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  /// Format phone number to international format without + sign (e.g., 639123456789)
  /// iprogsms.com requires format: 639XXXXXXXXX (no + sign, no spaces)
  static String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If it starts with 0, replace with country code 63 (Philippines)
    if (cleaned.startsWith('0')) {
      cleaned = '63${cleaned.substring(1)}';
    }
    // If it doesn't start with country code, add 63
    else if (!cleaned.startsWith('63')) {
      cleaned = '63$cleaned';
    }
    
    // Return without + sign (iprogsms.com format)
    return cleaned;
  }
  
  /// Format phone number with + for storage/display
  static String _formatPhoneNumberForStorage(String phoneNumber) {
    final formatted = _formatPhoneNumber(phoneNumber);
    return '+$formatted';
  }
  
  /// Send OTP via SMS using iprogsms.com API
  /// API endpoint: POST https://www.iprogsms.com/api/v1/sms_messages
  /// Parameters: api_token, phone_number, message, sms_provider (optional)
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      // Initialize cache if not already done
      await _initializeCache();
      
      // Format phone for API (without + sign)
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      // Format phone for storage (with + sign)
      final formattedPhoneForStorage = _formatPhoneNumberForStorage(phoneNumber);
      final otp = _generateOtp();
      
      // Store OTP with expiry (5 minutes)
      // Store with multiple formats to ensure we can find it during verification
      final phoneWithoutPlus = formattedPhoneForStorage.replaceFirst('+', '');
      final normalizedOriginal = phoneNumber.trim();
      
      // Store with all possible formats (use Set to avoid duplicates)
      final storageKeys = <String>{
        formattedPhoneForStorage,
        phoneWithoutPlus,
        normalizedOriginal,
      };
      
      final expiryTime = DateTime.now().add(const Duration(minutes: 5));
      
      // Store in cache
      for (final key in storageKeys) {
        _otpStorageCache[key] = otp;
        _otpExpiryCache[key] = expiryTime;
      }
      
      // Persist to SharedPreferences
      await _saveToStorage();
      
      print('=== OTP Storage Debug ===');
      print('Input phone: "$phoneNumber"');
      print('Formatted phone (with +): "$formattedPhoneForStorage"');
      print('Phone without +: "$phoneWithoutPlus"');
      print('Normalized original: "$normalizedOriginal"');
      print('Generated OTP: "$otp"');
      print('Stored with keys: $storageKeys');
      
      // Prepare the message
      final message = 'Your NutriPlan verification code is: $otp. Valid for 5 minutes.';
      
      // Make API request to iprogsms.com
      // Endpoint: POST https://www.iprogsms.com/api/v1/sms_messages
      final response = await http.post(
        Uri.parse('$_baseUrl/sms_messages'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'api_token': _apiKey,
          'phone_number': formattedPhone, // Format: 639XXXXXXXXX (no + sign)
          'message': message,
          'sms_provider': 0, // Optional: 0, 1, or 2; default is 0
        }),
      );
      
      print('SMS API Response Status: ${response.statusCode}');
      print('SMS API Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse response
        try {
          final responseData = jsonDecode(response.body);
          // Check if response indicates success
          if (responseData['status'] == 'success' || 
              responseData['success'] == true || 
              responseData['message'] != null) {
            return {
              'success': true,
              'message': 'OTP sent successfully',
              'phone': formattedPhoneForStorage,
            };
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? responseData['error'] ?? 'Failed to send OTP',
            };
          }
        } catch (_) {
          // If response is not JSON or parsing fails, assume success for 200/201 status
          return {
            'success': true,
            'message': 'OTP sent successfully',
            'phone': formattedPhoneForStorage,
          };
        }
      } else {
        // Parse error response
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? errorData['error'] ?? 'Failed to send OTP. Status: ${response.statusCode}',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Failed to send OTP. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP: ${e.toString()}',
      };
    }
  }
  
  
  /// Verify OTP
  static Future<bool> verifyOtp(String phoneNumber, String otp) async {
    // Initialize cache if not already done
    await _initializeCache();
    
    // Normalize the OTP (remove any whitespace)
    final normalizedOtp = otp.trim().replaceAll(' ', '');
    
    // Generate all possible phone number formats to check
    final formattedPhone = _formatPhoneNumberForStorage(phoneNumber);
    final phoneWithoutPlus = formattedPhone.replaceFirst('+', '');
    final originalPhone = phoneNumber.trim();
    
    // Also try formatting the original phone again in case it's different
    final formattedOriginal = _formatPhoneNumberForStorage(originalPhone);
    
    // Try to find the OTP in storage using all possible formats
    List<String> keysToCheck = [
      formattedPhone,
      phoneWithoutPlus,
      originalPhone,
      formattedOriginal,
    ];
    
    // Remove duplicates
    keysToCheck = keysToCheck.toSet().toList();
    
    String? storedOtp;
    String? storageKey;
    
    for (final key in keysToCheck) {
      if (_otpStorageCache.containsKey(key)) {
        storedOtp = _otpStorageCache[key];
        storageKey = key;
        break;
      }
    }
    
    if (storedOtp == null || storageKey == null) {
      return false;
    }
    
    // Check if OTP has expired
    if (!_otpExpiryCache.containsKey(storageKey) || _otpExpiryCache[storageKey]!.isBefore(DateTime.now())) {
      // Remove expired OTP
      for (final key in keysToCheck) {
        _otpStorageCache.remove(key);
        _otpExpiryCache.remove(key);
      }
      await _saveToStorage();
      return false;
    }
    
    // Normalize stored OTP for comparison
    final normalizedStoredOtp = storedOtp.trim().replaceAll(' ', '');
    
    // Verify OTP (compare as strings)
    if (normalizedStoredOtp == normalizedOtp) {
      // Remove OTP after successful verification - only remove formats for THIS phone number
      // Remove all keys that were checked (they all represent the same phone number)
      for (final key in keysToCheck) {
        if (_otpStorageCache.containsKey(key) && _otpStorageCache[key] == normalizedStoredOtp) {
          _otpStorageCache.remove(key);
          _otpExpiryCache.remove(key);
        }
      }
      await _saveToStorage();
      return true;
    }
    
    // DO NOT remove OTP on failure - allow user to try again
    return false;
  }
  
  /// Check if phone number is valid
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid length (10-13 digits for Philippines)
    if (cleaned.length < 10 || cleaned.length > 13) {
      return false;
    }
    
    return true;
  }
  
  /// Clear expired OTPs
  static Future<void> _clearExpiredOtps() async {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _otpExpiryCache.forEach((phone, expiry) {
      if (expiry.isBefore(now)) {
        keysToRemove.add(phone);
      }
    });
    
    for (final key in keysToRemove) {
      _otpStorageCache.remove(key);
      _otpExpiryCache.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      await _saveToStorage();
    }
  }
  
  /// Clear expired OTPs (public method)
  static Future<void> clearExpiredOtps() async {
    await _initializeCache();
    await _clearExpiredOtps();
  }
}

