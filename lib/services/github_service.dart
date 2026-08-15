import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/github_config.dart';
import 'crypto_service.dart';

/// GitHub 用户信息
class GitHubUser {
  const GitHubUser({
    required this.login,
    required this.name,
    required this.avatarUrl,
    required this.htmlUrl,
  });

  final String login;
  final String name;
  final String avatarUrl;
  final String htmlUrl;

  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    return GitHubUser(
      login: json['login'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }
}

/// GitHub 仓库信息
class GitHubRepo {
  const GitHubRepo({
    required this.name,
    required this.fullName,
    required this.private,
    required this.htmlUrl,
    required this.defaultBranch,
  });

  final String name;
  final String fullName;
  final bool private;
  final String htmlUrl;
  final String defaultBranch;

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    return GitHubRepo(
      name: json['name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      private: json['private'] as bool? ?? false,
      htmlUrl: json['html_url'] as String? ?? '',
      defaultBranch: json['default_branch'] as String? ?? 'main',
    );
  }
}

/// GitHub 仓库文件信息
class GitHubFile {
  const GitHubFile({
    required this.name,
    required this.path,
    required this.sha,
    required this.size,
  });

  final String name;
  final String path;
  final String sha;
  final int size;

  factory GitHubFile.fromJson(Map<String, dynamic> json) {
    return GitHubFile(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      sha: json['sha'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }
}

/// GitHub OAuth + API 服务
///
/// 提供完整的 GitHub OAuth 认证流程和 REST API 调用能力。
/// Token 通过 [EncryptionService] 加密后存储。
class GitHubService {
  GitHubService(this._crypto, [http.Client? client])
      : _client = client ?? http.Client();

  final EncryptionService _crypto;
  final http.Client _client;

  /// 从授权码交换 access_token
  ///
  /// 使用 authorization_code 向 GitHub token 端点发起 POST 请求，
  /// 成功返回 access_token，失败抛出异常。
  Future<String> exchangeCodeForToken(String code) async {
    final response = await _client.post(
      Uri.parse(GitHubConfig.tokenUrl),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'client_id': GitHubConfig.clientId,
        'client_secret': GitHubConfig.clientSecret,
        'code': code,
        'redirect_uri': GitHubConfig.redirectUri,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Token 交换失败: HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = body['access_token'] as String?;

    if (accessToken == null) {
      final error = body['error_description'] ?? body['error'] ?? '未知错误';
      throw Exception('Token 交换失败: $error');
    }

    return accessToken;
  }

  /// 加密 token 用于安全存储
  String encryptToken(String token) => _crypto.encrypt(token);

  /// 解密存储的 token
  String decryptToken(String encrypted) => _crypto.decrypt(encrypted);

  /// 获取已认证用户信息
  Future<GitHubUser> getUser(String token) async {
    final response = await _client.get(
      Uri.parse('${GitHubConfig.apiBaseUrl}/user'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('获取用户信息失败: HTTP ${response.statusCode}');
    }

    return GitHubUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// 列出用户仓库
  Future<List<GitHubRepo>> listRepos(String token,
      {int perPage = 30, int page = 1}) async {
    final response = await _client.get(
      Uri.parse(
        '${GitHubConfig.apiBaseUrl}/user/repos'
        '?per_page=$perPage&page=$page&sort=updated',
      ),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('获取仓库列表失败: HTTP ${response.statusCode}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => GitHubRepo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 创建仓库
  Future<GitHubRepo> createRepo(
    String token,
    String name, {
    String description = '',
    bool private = true,
  }) async {
    final response = await _client.post(
      Uri.parse('${GitHubConfig.apiBaseUrl}/user/repos'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'name': name,
        'description': description,
        'private': private,
        'auto_init': true,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('创建仓库失败: HTTP ${response.statusCode}');
    }

    return GitHubRepo.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// 创建或更新文件
  ///
  /// 向指定仓库写入文件内容。若文件已存在，需提供 sha（通过 getFile 获取）。
  Future<void> createOrUpdateFile({
    required String token,
    required String owner,
    required String repo,
    required String path,
    required String content,
    required String message,
    String? sha,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'content': base64Encode(utf8.encode(content)),
    };
    if (sha != null) body['sha'] = sha;

    final response = await _client.put(
      Uri.parse(
        '${GitHubConfig.apiBaseUrl}/repos/$owner/$repo/contents/$path',
      ),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMsg = errorBody['message'] ?? 'HTTP ${response.statusCode}';
      throw Exception('写入文件失败: $errorMsg');
    }
  }

  /// 获取文件内容
  ///
  /// 返回文件内容的 Base64 解码字符串和 SHA。
  /// 文件不存在时返回 null。
  Future<({String content, String sha})?> getFile({
    required String token,
    required String owner,
    required String repo,
    required String path,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '${GitHubConfig.apiBaseUrl}/repos/$owner/$repo/contents/$path',
      ),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('获取文件失败: HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final contentBase64 = body['content'] as String? ?? '';
    final sha = body['sha'] as String? ?? '';
    final content = utf8.decode(base64Decode(contentBase64.replaceAll('\n', '')));

    return (content: content, sha: sha);
  }

  /// 删除文件
  Future<void> deleteFile({
    required String token,
    required String owner,
    required String repo,
    required String path,
    required String message,
    required String sha,
  }) async {
    final response = await _client.delete(
      Uri.parse(
        '${GitHubConfig.apiBaseUrl}/repos/$owner/$repo/contents/$path',
      ),
      headers: _authHeaders(token),
      body: jsonEncode({'message': message, 'sha': sha}),
    );

    if (response.statusCode != 200) {
      throw Exception('删除文件失败: HTTP ${response.statusCode}');
    }
  }

  /// 列出仓库目录下的文件
  ///
  /// 返回文件名列表（不含目录）。目录不存在时返回空列表。
  Future<List<GitHubFile>> listFiles({
    required String token,
    required String owner,
    required String repo,
    required String path,
  }) async {
    final response = await _client.get(
      Uri.parse(
        '${GitHubConfig.apiBaseUrl}/repos/$owner/$repo/contents/$path',
      ),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception('列出文件失败: HTTP ${response.statusCode}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .where((e) => (e as Map<String, dynamic>)['type'] == 'file')
        .map((e) => GitHubFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 构建认证请求头
  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };
}
