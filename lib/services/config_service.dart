import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final Dio _dio = Dio();
  
  // Placeholder for OSS URLs. The user will provide these before compilation.
  // We support multiple URLs for polling.
  final List<String> _ossUrls = [
    'https://baota.sbs/xuexi.txt', 
    'https://baota.sbs/xuexi2.txt'
  ];

  AppConfig? _appConfig;
  String? _currentApiUrl;

  AppConfig? get appConfig => _appConfig;
  String? get currentApiUrl => _currentApiUrl;

  String? _lastError;
  String? get lastError => _lastError;

  /// Initialize and fetch config from OSS
  Future<bool> init() async {
    _lastError = null;
    for (String url in _ossUrls) {
      try {
        print('Fetching config from: $url');
        final response = await _dio.get(
          '$url?t=${DateTime.now().millisecondsSinceEpoch}',
          options: Options(
            responseType: ResponseType.plain,
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': '*/*',
            },
          ),
        );
        print('Response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          String rawData = response.data.toString().trim();
          print('Raw data length: ${rawData.length}');
          print('Raw data preview: ${rawData.substring(0, rawData.length > 20 ? 20 : rawData.length)}...');
          
          // Decode Base64
          try {
            // Remove any whitespace just in case
            rawData = rawData.replaceAll(RegExp(r'\s+'), '');
            String decodedJson = utf8.decode(base64Decode(rawData));
            
            // Remove BOM if present
            if (decodedJson.startsWith('\uFEFF')) {
              decodedJson = decodedJson.substring(1);
            }

            // Try to fix common JSON errors like trailing commas
            // 1. Trailing comma before closing brace: {"a":1,} -> {"a":1}
            decodedJson = decodedJson.replaceAll(RegExp(r',\s*}'), '}');
            // 2. Trailing comma before closing bracket: [1,] -> [1]
            decodedJson = decodedJson.replaceAll(RegExp(r',\s*]'), ']');
            // 3. Trailing comma at the end of the file: {...}, -> {...}
            decodedJson = decodedJson.replaceAll(RegExp(r',\s*$'), '');

            print('Cleaned JSON: $decodedJson');

            // Parse JSON
            Map<String, dynamic> jsonMap = jsonDecode(decodedJson);
            _appConfig = AppConfig.fromJson(jsonMap);
            
            // Select API URL
            await _selectApiUrl();
            
            return true; // Success
          } catch (e) {
            print('Decoding/Parsing error: $e');
            _lastError = 'Parse Error: $e';
            // Try next URL if parsing fails? Or stop? 
            // Usually if content is bad, next URL might be same content. But let's continue.
          }
        } else {
          _lastError = 'HTTP ${response.statusCode}';
        }
      } catch (e) {
        print('Failed to fetch from $url: $e');
        _lastError = 'Fetch Error: $e';
        // Continue to next URL
      }
    }
    if (_lastError == null) _lastError = 'Unknown error (All URLs failed)';
    return false; // All URLs failed
  }

  /// Select the best API URL from the list
  Future<void> _selectApiUrl() async {
    if (_appConfig == null || _appConfig!.domains.isEmpty) return;

    // For now, we simply pick the first one. 
    // In production, we might want to ping them to find the fastest one.
    String domain = _appConfig!.domains.first;
    String path = _appConfig!.apiPath;
    
    // Ensure domain doesn't end with / and path doesn't start with /
    if (domain.endsWith('/')) domain = domain.substring(0, domain.length - 1);
    if (path.startsWith('/')) path = path.substring(1);
    
    _currentApiUrl = '$domain/$path';
    print('Selected API URL: $_currentApiUrl');
  }

  /// Check for updates
  Future<String?> checkUpdate() async {
    if (_appConfig == null) return null;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    String? latestVersion;

    if (Platform.isWindows) {
      latestVersion = _appConfig!.versions['windows'];
    } else if (Platform.isMacOS) {
      latestVersion = _appConfig!.versions['macos'];
    } else if (Platform.isAndroid) {
      latestVersion = _appConfig!.versions['android'];
    }

    if (latestVersion != null && _compareVersions(latestVersion, currentVersion) > 0) {
      return _appConfig!.downloadUrl;
    }
    return null;
  }

  int _compareVersions(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map(int.parse).toList();
    List<int> v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return 0;
  }
}
