// BINUSA SAFESPACE - DATA NORMALIZATION SCRIPT
// ==============================================
//
// Run: dart run scripts/normalize_users.dart
//
// Requires: service_account.json from Firebase Console
//   Settings > Service Accounts > Generate New Private Key
//
// Set env: GOOGLE_APPLICATION_CREDENTIALS=path/to/service_account.json
//
// This script normalizes the users collection:
//   1. Normalizes 'department' (TKJ/tjkt/Teknik Jaringan -> TJKT)
//   2. Normalizes 'role' (Student/siswa/murid -> student)
//   3. Copies 'class' -> 'className' if className is missing
//   4. Normalizes className format (e.g. "XII TJKT 1" format)
//   5. Skips already-valid users

import 'dart:convert';
import 'dart:io';

final String projectId = Platform.environment['FIREBASE_PROJECT_ID'] ?? 'binusa-safespace';
final String? credentialsPath = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];

void main() async {
  print('=== BINUSA SAFESPACE DATA NORMALIZATION ===\n');

  if (credentialsPath == null) {
    print('ERROR: Set GOOGLE_APPLICATION_CREDENTIALS environment variable');
    print('Example: \$env:GOOGLE_APPLICATION_CREDENTIALS=\"path/to/service_account.json\"');
    exit(1);
  }

  final credFile = File(credentialsPath!);
  if (!credFile.existsSync()) {
    print('ERROR: Service account file not found at: $credentialsPath');
    exit(1);
  }

  final credentials = jsonDecode(credFile.readAsStringSync());
  final accessToken = await _getAccessToken(credentials);

  if (accessToken == null) {
    print('ERROR: Failed to get access token');
    exit(1);
  }

  print('Fetching all users...\n');

  final users = await _getAllUsers(accessToken);
  print('Found ${users.length} users.\n');

  int modified = 0;
  int skipped = 0;

  for (final user in users) {
    final updates = <String, dynamic>{};
    final uid = user['name'].split('/').last;
    final data = user['fields'] ?? {};

    // Normalize department
    final dept = _getField(data, 'department');
    if (dept != null) {
      final normalized = _normalizeDepartment(dept);
      if (normalized != dept) {
        updates['department'] = _stringValue(normalized);
        print('  [$uid] department: "$dept" -> "$normalized"');
      }
    }

    // Normalize role
    final role = _getField(data, 'role');
    if (role != null) {
      final normalized = _normalizeRole(role);
      if (normalized != role) {
        updates['role'] = _stringValue(normalized);
        print('  [$uid] role: "$role" -> "$normalized"');
      }
    }

    // Copy class -> className if className missing
    final className = _getField(data, 'className');
    final classField = _getField(data, 'class');
    if ((className == null || className.isEmpty) && classField != null && classField.isNotEmpty) {
      updates['className'] = _stringValue(classField);
      updates['class'] = _stringValue(classField);
      print('  [$uid] className missing -> copied from class: "$classField"');
    }

    // Normalize className format (ensure proper spacing)
    final finalClassName = updates['className']?['stringValue'] as String? ?? className;
    if (finalClassName != null && finalClassName.isNotEmpty) {
      final normalized = _normalizeClassName(finalClassName);
      if (normalized != finalClassName) {
        updates['className'] = _stringValue(normalized);
        updates['class'] = _stringValue(normalized);
        print('  [$uid] className: "$finalClassName" -> "$normalized"');
      }
    }

    if (updates.isNotEmpty) {
      await _updateUser(accessToken, uid, updates);
      modified++;
    } else {
      skipped++;
    }
  }

  print('\n=== SUMMARY ===');
  print('Modified: $modified users');
  print('Skipped: $skipped users');
  print('Total: ${users.length} users');
}

String _normalizeDepartment(String dept) {
  final map = {
    'tkj': 'TJKT',
    'tjkt': 'TJKT',
    'teknik jaringan': 'TJKT',
    'teknik komputer dan jaringan': 'TJKT',
    'dkv': 'DKV',
    'desain komunikasi visual': 'DKV',
    'mplb': 'MPLB',
    'manajemen perkantoran': 'MPLB',
    'manajemen perkantoran dan layanan bisnis': 'MPLB',
    'akl': 'AKL',
    'akuntansi': 'AKL',
    'akuntansi dan keuangan lembaga': 'AKL',
  };
  return map[dept.toLowerCase().trim()] ?? dept;
}

String _normalizeRole(String role) {
  final map = {
    'student': 'student',
    'siswa': 'student',
    'murid': 'student',
    'pelajar': 'student',
    'admin': 'admin',
    'guru bk': 'admin',
    'konselor': 'admin',
    'wali kelas': 'waliKelas',
    'walikelas': 'waliKelas',
    'guru': 'waliKelas',
  };
  return map[role.toLowerCase().trim()] ?? role;
}

String _normalizeClassName(String cn) {
  // Normalize: "XII-TJKT-1" -> "XII TJKT 1", "Xi TJKT 1" -> "XI TJKT 1", etc.
  var result = cn
      .replaceAll('-', ' ')
      .replaceAll('  ', ' ')
      .trim()
      .toUpperCase();
  // Fix common issues
  result = result
      .replaceAll(' X ', ' X ')
      .replaceAll(' XI ', ' XI ')
      .replaceAll(' XII ', ' XII ')
      .trim();
  // Ensure single spaces
  result = result.split(' ').where((s) => s.isNotEmpty).join(' ');
  return result;
}

String? _getField(Map<String, dynamic> data, String field) {
  final f = data[field];
  if (f == null) return null;
  return f['stringValue'] as String? ?? f['integerValue'] as String?;
}

Map<String, dynamic> _stringValue(String value) => {'stringValue': value};

Future<String?> _getAccessToken(Map<String, dynamic> credentials) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('https://oauth2.googleapis.com/token'));
    request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
    request.write('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${_createJWT(credentials)}');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body)['access_token'] as String?;
  } catch (e) {
    print('Auth error: $e');
    return null;
  } finally {
    client.close();
  }
}

String _createJWT(Map<String, dynamic> cred) {
  // Simplified - in production use a JWT library.
  // For now, we'll use the access token from the service account directly.
  return cred['private_key'] as String? ?? '';
}

Future<List<Map<String, dynamic>>> _getAllUsers(String token) async {
  final client = HttpClient();
  try {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users';
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('Authorization', 'Bearer $token');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final result = jsonDecode(body);
    return (result['documents'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  } catch (e) {
    print('Error fetching users: $e');
    return [];
  } finally {
    client.close();
  }
}

Future<void> _updateUser(String token, String uid, Map<String, dynamic> updates) async {
  final client = HttpClient();
  try {
    final url = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid';
    // Firestore REST API patch
    final request = await client.patchUrl(Uri.parse(url));
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.contentType = ContentType('application', 'json');
    request.write(jsonEncode({
      'fields': updates,
    }));
    await request.close();
  } catch (e) {
    print('Error updating $uid: $e');
  } finally {
    client.close();
  }
}
