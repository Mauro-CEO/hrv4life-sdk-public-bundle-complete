import 'package:dio/dio.dart';
import '../models/frame_data.dart';
import '../models/hrv_result.dart';
import '../models/hrv_group.dart';

/// Internal service for API communication.
class ApiService {
  static const String _defaultBaseUrl = 'https://api.hrv4life.com/api';

  final String apiKey;
  final String patientKey;
  final String baseUrl;
  final Dio _dio;

  ApiService({
    required this.apiKey,
    required this.patientKey,
    String? baseUrl,
    String locale = 'pt',
  })  : baseUrl = baseUrl ?? _defaultBaseUrl,
        _dio = Dio() {
    _dio.options.baseUrl = this.baseUrl;
    _dio.options.headers = {
      'X-API-KEY': apiKey,
      'X-Customer-Key': patientKey,
      'Content-Type': 'application/json',
      'Accept-Language': locale,
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  /// Updates the Accept-Language header for subsequent requests.
  set locale(String lang) {
    _dio.options.headers['Accept-Language'] = lang;
  }

  /// Analyzes the captured frame data and returns HRV metrics.
  Future<HrvResult> analyze({
    required List<FrameData> frames,
    Map<String, dynamic>? metadata,
  }) async {
    print('[HRV-SDK] ========== API REQUEST ==========');
    print('[HRV-SDK] URL: $baseUrl/sdk/readings');
    print('[HRV-SDK] X-API-KEY: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}');
    print('[HRV-SDK] X-Patient-Key: ${patientKey.substring(0, 4)}...${patientKey.substring(patientKey.length - 4)}');
    print('[HRV-SDK] Frames: ${frames.length}');
    print('[HRV-SDK] Metadata: $metadata');

    try {
      final response = await _dio.post(
        '/sdk/readings',
        data: {
          'frames': frames.map((f) => f.toJson()).toList(),
          'metadata': metadata ?? {},
          if (metadata?['duration'] is num)
            'duration': (metadata!['duration'] as num).toInt(),
        },
      );

      print('[HRV-SDK] ========== API RESPONSE ==========');
      print('[HRV-SDK] Status: ${response.statusCode}');
      print('[HRV-SDK] Data: ${response.data}');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final data = response.data as Map<String, dynamic>;
        print('[HRV-SDK] Success: true');
        return HrvResult.fromJson(data);
      } else {
        print('[HRV-SDK] Success: false - Unexpected response');
        return HrvResult.error('Unexpected response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('[HRV-SDK] ========== API ERROR ==========');
      print('[HRV-SDK] Type: ${e.type}');
      print('[HRV-SDK] Message: ${e.message}');
      print('[HRV-SDK] Response: ${e.response?.data}');

      String message;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timeout';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection';
          break;
        case DioExceptionType.badResponse:
          message = 'Server error: ${e.response?.statusCode}';
          break;
        default:
          message = 'Network error: ${e.message}';
      }
      print('[HRV-SDK] Final message: $message');
      return HrvResult.error(message);
    } catch (e) {
      print('[HRV-SDK] ========== UNEXPECTED ERROR ==========');
      print('[HRV-SDK] Error: $e');
      return HrvResult.error('Unexpected error: $e');
    }
  }

  /// Performs a lightweight signal quality check.
  ///
  /// Sends a small sample of frames (3-10 seconds) to the API
  /// for quality assessment. Returns quality level and suggestions.
  /// Does NOT consume daily quota or save data.
  Future<SignalCheckResult> signalCheck({
    required List<FrameData> frames,
  }) async {
    try {
      final response = await _dio.post(
        '/sdk/readings/signal-check',
        data: {
          'frames': frames.map((f) => f.toJson()).toList(),
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return SignalCheckResult.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return SignalCheckResult.fallback();
    } catch (e) {
      // On any error, return acceptable so measurement continues
      return SignalCheckResult.fallback();
    }
  }

  /// Validates the current customer key against the API.
  /// Returns true if the user exists and is authorized.
  Future<bool> validateUser() async {
    try {
      final response = await _dio.get('/sdk/groups');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ===== GROUP METHODS =====

  /// List groups the current user belongs to.
  Future<List<HrvGroup>> getGroups() async {
    try {
      final response = await _dio.get('/sdk/groups');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((g) => HrvGroup.fromJson(g as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create a new group.
  Future<HrvGroup?> createGroup(String name, String? description) async {
    try {
      final response = await _dio.post('/sdk/groups', data: {
        'name': name,
        if (description != null) 'description': description,
      });
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return HrvGroup.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get group details with members.
  Future<Map<String, dynamic>?> getGroupDetail(String groupId) async {
    try {
      final response = await _dio.get('/sdk/groups/$groupId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Join a group by invite code.
  Future<HrvGroup?> joinGroup(String inviteCode) async {
    try {
      final response = await _dio.post('/sdk/groups/join', data: {
        'inviteCode': inviteCode,
      });
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return HrvGroup.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Leave a group.
  Future<bool> leaveGroup(String groupId) async {
    try {
      final response = await _dio.post('/sdk/groups/$groupId/leave');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Add a member to a group by customer key.
  Future<bool> addGroupMember(String groupId, String customerKey) async {
    try {
      final response = await _dio.post('/sdk/groups/$groupId/members', data: {
        'customerKey': customerKey,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Remove a member from a group.
  Future<bool> removeGroupMember(String groupId, String memberId) async {
    try {
      final response = await _dio.delete('/sdk/groups/$groupId/members/$memberId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update a member's role.
  Future<bool> updateGroupMemberRole(String groupId, String memberId, String role) async {
    try {
      final response = await _dio.patch('/sdk/groups/$groupId/members/$memberId', data: {
        'role': role,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete a group.
  Future<bool> deleteGroup(String groupId) async {
    try {
      final response = await _dio.delete('/sdk/groups/$groupId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Accept a group invite (status INVITED → ACTIVE).
  Future<bool> acceptGroupInvite(String groupId) async {
    try {
      final response = await _dio.post('/sdk/groups/$groupId/accept-invite');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Decline a group invite (deletes membership).
  Future<bool> declineGroupInvite(String groupId) async {
    try {
      final response = await _dio.post('/sdk/groups/$groupId/decline-invite');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get pending/invited members of a group (ADMIN/MODERATOR only).
  Future<List<HrvGroupMember>> getPendingMembers(String groupId) async {
    try {
      final response = await _dio.get('/sdk/groups/$groupId/pending');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((m) => HrvGroupMember.fromJson(m as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Approve a pending member (ADMIN/MODERATOR only).
  Future<bool> approveMember(String groupId, String memberId) async {
    try {
      final response = await _dio.post('/sdk/groups/$groupId/members/$memberId/approve');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Reject a pending member (ADMIN/MODERATOR only).
  Future<bool> rejectMember(String groupId, String memberId) async {
    try {
      final response = await _dio.post('/sdk/groups/$groupId/members/$memberId/reject');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Regenerate invite code.
  Future<String?> regenerateGroupInviteCode(String groupId) async {
    try {
      final response = await _dio.post('/sdk/groups/$groupId/regenerate-code');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as Map<String, dynamic>)['inviteCode'] as String?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get readings for a specific group member.
  Future<Map<String, dynamic>?> getMemberReadings(
    String groupId,
    String memberId, {
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/sdk/groups/$groupId/members/$memberId/readings',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the full detail of a specific group member reading.
  /// Returns the complete analysis data needed for HrvResultPage.
  Future<Map<String, dynamic>?> getMemberReadingDetail(
    String groupId,
    String memberId,
    String readingId,
  ) async {
    try {
      final response = await _dio.get(
        '/sdk/groups/$groupId/members/$memberId/readings/$readingId',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Disposes of API service resources.
  void dispose() {
    _dio.close();
  }
}

/// Result of a signal quality pre-check.
class SignalCheckResult {
  final String quality;
  final bool acceptable;
  final double snr;
  final int peaksDetected;
  final double validFramesRatio;
  final double stability;
  final List<String> suggestions;

  SignalCheckResult({
    required this.quality,
    required this.acceptable,
    required this.snr,
    required this.peaksDetected,
    required this.validFramesRatio,
    required this.stability,
    required this.suggestions,
  });

  factory SignalCheckResult.fromJson(Map<String, dynamic> json) {
    return SignalCheckResult(
      quality: json['quality'] as String? ?? 'fair',
      acceptable: json['acceptable'] as bool? ?? true,
      snr: (json['snr'] as num?)?.toDouble() ?? 0,
      peaksDetected: json['peaksDetected'] as int? ?? 0,
      validFramesRatio: (json['validFramesRatio'] as num?)?.toDouble() ?? 0,
      stability: (json['stability'] as num?)?.toDouble() ?? 0,
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Fallback result when API is unreachable — never blocks measurement.
  factory SignalCheckResult.fallback() {
    return SignalCheckResult(
      quality: 'fair',
      acceptable: true,
      snr: 0,
      peaksDetected: 0,
      validFramesRatio: 0,
      stability: 0,
      suggestions: [],
    );
  }
}
