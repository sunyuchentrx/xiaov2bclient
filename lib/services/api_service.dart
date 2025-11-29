import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';
import 'config_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json',
    },
    validateStatus: (status) => status! < 600,
  ));

  // Helper to get the full API URL
  String? get _baseUrl => ConfigService().currentApiUrl;

  Future<String?> login(String email, String password) async {
    if (_baseUrl == null) return 'Config not loaded. Please restart app.';

    final url = '$_baseUrl/passport/auth/login';
    
    try {
      print('Attempting login to: $url');
      final response = await _dio.post(
        url,
        data: {'email': email, 'password': password},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      print('Login response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 && response.data['data'] != null) {
        final authData = response.data['data']['auth_data'];
        if (authData != null) {
          await _saveToken(authData);
          return null; // Success
        }
        return 'Token not found in response';
      } else if (response.data != null && response.data['message'] != null) {
        return response.data['message'].toString();
      }
      return 'Login failed: ${response.statusCode}';
    } catch (e) {
      print('Login error: $e');
      return 'Connection error: $e';
    }
  }

  Future<String?> register(String email, String password, {String? inviteCode, String? emailCode}) async {
    if (_baseUrl == null) return 'Config not loaded';

    try {
      final data = {
        'email': email,
        'password': password,
        'invite_code': inviteCode,
        'email_code': emailCode,
      };
      // Remove null values
      data.removeWhere((key, value) => value == null);

      final response = await _dio.post(
        '$_baseUrl/passport/auth/register',
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final authData = response.data['data']['auth_data'];
        if (authData != null) {
          await _saveToken(authData);
          return null; // Success
        }
      }
      if (response.data != null && response.data['message'] != null) {
        return response.data['message'].toString();
      }
      return 'Registration failed';
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'];
        if (msg != null) return msg.toString();
      }
      return 'Error: $e';
    }
  }

  Future<String?> forgetPassword(String email, String password, String emailCode) async {
    if (_baseUrl == null) return 'Config not loaded';

    try {
      final response = await _dio.post(
        '$_baseUrl/passport/auth/forget',
        data: {
          'email': email,
          'password': password,
          'email_code': emailCode,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data['data'] == true) {
        return null; // Success
      }
      if (response.data != null && response.data['message'] != null) {
        return response.data['message'].toString();
      }
      return 'Reset failed';
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'];
        if (msg != null) return msg.toString();
      }
      return 'Error: $e';
    }
  }

  Future<String?> sendEmailVerify(String email) async {
    if (_baseUrl == null) return 'Config not loaded';
    try {
      final response = await _dio.post(
        '$_baseUrl/passport/comm/sendEmailVerify',
        data: {'email': email},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200 && response.data['data'] == true) {
        return null; // Success
      }
      if (response.data != null && response.data['message'] != null) {
        return response.data['message'].toString();
      }
      return 'Failed to send code';
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'];
        if (msg != null) return msg.toString();
      }
      return 'Error: $e';
    }
  }

  Future<Map<String, dynamic>?> getSubscribe() async {
    final result = await _get('/user/getSubscribe');
    if (result is Map<String, dynamic>) {
      return result;
    }
    return null;
  }

  Future<List<dynamic>?> fetchServerNodes() async {
    final response = await _get('/user/server/fetch');
    if (response != null && response['data'] is List) {
      return response['data'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final response = await _get('/user/info');
    if (response != null && response['data'] != null) {
      return response['data'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getInviteData() async {
    final response = await _get('/user/invite/fetch');
    if (response != null && response['data'] != null) {
      return response['data'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWebsiteConfig() async {
    if (_baseUrl == null) return null;
    try {
      final response = await _dio.get(
        '$_baseUrl/guest/comm/config',
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
    } catch (e) {
      print('Get website config error: $e');
    }
    return null;
  }

  // Shop & Payment APIs
  Future<List<dynamic>?> fetchPlans() async {
    final response = await _get('/user/plan/fetch');
    if (response != null && response['data'] is List) {
      return response['data'];
    }
    return null;
  }

  // Returns trade_no on success, or throws error message on failure
  Future<String> submitOrder({required int planId, required String period}) async {
    try {
      final response = await _post('/user/order/save', {
        'plan_id': planId,
        'period': period,
      });
      
      if (response != null && response['data'] != null) {
        return response['data'].toString();
      }
      throw 'Unknown error';
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'];
        if (msg != null) throw msg;
      }
      rethrow;
    }
  }

  Future<List<dynamic>?> fetchOrders() async {
    final response = await _get('/user/order/fetch');
    if (response != null && response['data'] is List) {
      return response['data'];
    }
    return null;
  }

  Future<bool> cancelOrder(String tradeNo) async {
    try {
      final response = await _post('/user/order/cancel', {
        'trade_no': tradeNo,
      });
      return response != null && response['data'] == true;
    } catch (e) {
      print('Cancel order error: $e');
      return false;
    }
  }

  Future<List<dynamic>?> getPaymentMethods() async {
    final response = await _get('/user/order/getPaymentMethod');
    if (response != null && response['data'] is List) {
      return response['data'];
    }
    return null;
  }

  Future<String?> checkoutOrder({required String tradeNo, required int methodId}) async {
    final response = await _post('/user/order/checkout', {
      'trade_no': tradeNo,
      'method': methodId,
    });
    if (response != null) {
       return response['data']?.toString();
    }
    return null;
  }

  Future<dynamic> _get(String path) async {
    if (_baseUrl == null) return null;
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '$_baseUrl$path',
        options: Options(
          headers: {'Authorization': token},
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      print('GET $path failed: ${response.statusCode} - ${response.data}');
    } catch (e) {
      print('GET $path error: $e');
    }
    return null;
  }

  Future<dynamic> _post(String path, Map<String, dynamic> data) async {
    if (_baseUrl == null) return null;
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await _dio.post(
        '$_baseUrl$path',
        data: data,
        options: Options(
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      print('POST $path failed: ${response.statusCode} - ${response.data}');
      if (response.data is Map && response.data['message'] != null) {
        throw response.data['message'].toString();
      }
      throw 'Request failed: ${response.statusCode}';
    } catch (e) {
      if (e is DioException) {
        print('POST $path error: ${e.message}');
        if (e.response != null) {
          print('Response data: ${e.response?.data}');
        }
        rethrow; 
      } else if (e is String) {
        rethrow;
      } else {
        print('POST $path error: $e');
        throw e.toString();
      }
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    try {
      await _post('/user/changePassword', {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      return null;
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        return e.response!.data['message'];
      }
      return 'Failed to change password';
    } catch (e) {
      return 'An error occurred';
    }
  }

  Future<bool> updateUserInfo(Map<String, dynamic> data) async {
    try {
      await _post('/user/update', data);
      return true;
    } catch (e) {
      print('Update user info error: $e');
      return false;
    }
  }

  Future<bool> redeemGiftCard(String code) async {
    try {
      await _post('/user/redeemgiftcard', {'giftcard': code});
      return true;
    } catch (e) {
      if (e is String) rethrow;
      if (e is DioException && e.response?.data is Map && e.response!.data['message'] != null) {
        throw e.response!.data['message'];
      }
      throw 'Redemption failed';
    }
  }

  Future<List<dynamic>?> getTrafficLog() async {
    final response = await _get('/user/stat/getTrafficLog');
    if (response != null && response['data'] is List) {
      return response['data'];
    }
    return null;
  }

  Future<String?> generateInviteCode() async {
    try {
      final response = await _get('/user/invite/save');
      if (response != null && response['data'] != null) {
        return null; // Success
      }
      return 'Failed to generate code';
    } catch (e) {
      if (e is DioException && e.response?.data is Map && e.response!.data['message'] != null) {
        return e.response!.data['message'];
      }
      return 'Error: $e';
    }
  }

  // Ticket API
  Future<List<dynamic>?> fetchTicketList() async {
    final response = await _get('/user/ticket/fetch');
    if (response != null && response['data'] is List) {
      return response['data'];
    }
    return null;
  }

  Future<String?> createTicket(String subject, int level, String message) async {
    try {
      await _post('/user/ticket/save', {
        'subject': subject,
        'level': level,
        'message': message,
      });
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getTicketDetail(int id) async {
    final response = await _get('/user/ticket/fetch?id=$id');
    if (response != null && response['data'] != null) {
      return response['data'];
    }
    return null;
  }

  Future<String?> replyTicket(int id, String message) async {
    try {
      await _post('/user/ticket/reply', {
        'id': id,
        'message': message,
      });
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> closeTicket(int id) async {
    try {
      await _post('/user/ticket/close', {'id': id});
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });

      var apiUrl = ConfigService().appConfig?.imagebedApi;
      print('Configured ImageBed Value: $apiUrl');
      
      if (apiUrl == null || apiUrl.isEmpty) {
        print('Error: Image upload API not configured');
        return null;
      }

      // If the configured value is just a key (doesn't start with http), construct the ImgBB URL
      if (!apiUrl.startsWith('http')) {
        apiUrl = 'https://api.imgbb.com/1/upload?key=$apiUrl';
      }

      print('Uploading image to: $apiUrl');
      final response = await _dio.post(
        apiUrl,
        data: formData,
      );
      
      print('Upload response status: ${response.statusCode}');
      print('Upload response data: ${response.data}');

      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data']['url'];
      }
      return null;
    } catch (e) {
      print('Image upload failed: $e');
      if (e is DioException) {
        print('DioError response: ${e.response?.data}');
        print('DioError message: ${e.message}');
      }
      return null;
    }
  }
  Future<List<dynamic>?> fetchNotices() async {
    final response = await _get('/user/notice/fetch');
    if (response != null && response['data'] is List) {
      return response['data'];
    }
    return null;
  }
}
