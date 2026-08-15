import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/core/config/github_config.dart';
import 'package:flutter_notes/services/crypto_service.dart';
import 'package:flutter_notes/services/github_service.dart';

void main() {
  late SharedPreferences prefs;
  late EncryptionService crypto;
  const testToken = 'ghp_test_token_12345';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    crypto = EncryptionService(prefs);
  });

  group('GitHubService', () {
    group('exchangeCodeForToken', () {
      test('returns access_token on success', () async {
        final client = MockClient((request) async {
          expect(request.url.toString(), GitHubConfig.tokenUrl);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['code'], 'test_code');
          return http.Response(
            jsonEncode({'access_token': testToken, 'token_type': 'bearer'}),
            200,
          );
        });

        final service = GitHubService(crypto, client);
        final token = await service.exchangeCodeForToken('test_code');
        expect(token, testToken);
      });

      test('throws on HTTP error', () {
        final client = MockClient((request) async {
          return http.Response('Bad Request', 400);
        });

        final service = GitHubService(crypto, client);
        expect(
          () => service.exchangeCodeForToken('bad_code'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when access_token is missing', () {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({'error': 'bad_verification_code'}),
            200,
          );
        });

        final service = GitHubService(crypto, client);
        expect(
          () => service.exchangeCodeForToken('invalid'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('encryptToken / decryptToken', () {
      test('round-trip preserves original token', () {
        final service = GitHubService(crypto);
        final encrypted = service.encryptToken(testToken);
        final decrypted = service.decryptToken(encrypted);
        expect(decrypted, testToken);
      });

      test('encrypted token differs from plaintext', () {
        final service = GitHubService(crypto);
        final encrypted = service.encryptToken(testToken);
        expect(encrypted, isNot(testToken));
      });
    });

    group('getUser', () {
      test('returns GitHubUser on success', () async {
        final client = MockClient((request) async {
          expect(request.url.toString(), '${GitHubConfig.apiBaseUrl}/user');
          expect(
            request.headers['Authorization'],
            'Bearer $testToken',
          );
          return http.Response(
            jsonEncode({
              'login': 'testuser',
              'name': 'Test User',
              'avatar_url': 'https://avatar.url/test.png',
              'html_url': 'https://github.com/testuser',
            }),
            200,
          );
        });

        final service = GitHubService(crypto, client);
        final user = await service.getUser(testToken);

        expect(user.login, 'testuser');
        expect(user.name, 'Test User');
        expect(user.avatarUrl, 'https://avatar.url/test.png');
        expect(user.htmlUrl, 'https://github.com/testuser');
      });

      test('throws on HTTP error', () {
        final client = MockClient((request) async {
          return http.Response('Unauthorized', 401);
        });

        final service = GitHubService(crypto, client);
        expect(
          () => service.getUser(testToken),
          throwsA(isA<Exception>()),
        );
      });

      test('handles missing fields with defaults', () async {
        final client = MockClient((request) async {
          return http.Response(jsonEncode({}), 200);
        });

        final service = GitHubService(crypto, client);
        final user = await service.getUser(testToken);

        expect(user.login, '');
        expect(user.name, '');
      });
    });

    group('listRepos', () {
      test('returns list of repos on success', () async {
        final client = MockClient((request) async {
          expect(request.url.path, contains('/user/repos'));
          return http.Response(
            jsonEncode([
              {
                'name': 'repo1',
                'full_name': 'user/repo1',
                'private': false,
                'html_url': 'https://github.com/user/repo1',
                'default_branch': 'main',
              },
              {
                'name': 'repo2',
                'full_name': 'user/repo2',
                'private': true,
                'html_url': 'https://github.com/user/repo2',
                'default_branch': 'master',
              },
            ]),
            200,
          );
        });

        final service = GitHubService(crypto, client);
        final repos = await service.listRepos(testToken);

        expect(repos.length, 2);
        expect(repos[0].name, 'repo1');
        expect(repos[0].private, isFalse);
        expect(repos[1].name, 'repo2');
        expect(repos[1].private, isTrue);
        expect(repos[1].defaultBranch, 'master');
      });

      test('returns empty list when user has no repos', () async {
        final client = MockClient((request) async {
          return http.Response(jsonEncode([]), 200);
        });

        final service = GitHubService(crypto, client);
        final repos = await service.listRepos(testToken);
        expect(repos, isEmpty);
      });
    });

    group('createRepo', () {
      test('returns created repo on success', () async {
        final client = MockClient((request) async {
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['name'], 'my_notes');
          expect(body['private'], true);
          return http.Response(
            jsonEncode({
              'name': 'my_notes',
              'full_name': 'user/my_notes',
              'private': true,
              'html_url': 'https://github.com/user/my_notes',
              'default_branch': 'main',
            }),
            201,
          );
        });

        final service = GitHubService(crypto, client);
        final repo = await service.createRepo(testToken, 'my_notes');

        expect(repo.name, 'my_notes');
        expect(repo.private, isTrue);
      });

      test('throws on non-201 status', () {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({'message': 'Repository exists'}),
            422,
          );
        });

        final service = GitHubService(crypto, client);
        expect(
          () => service.createRepo(testToken, 'existing'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('createOrUpdateFile', () {
      test('sends base64-encoded content with message', () async {
        String? capturedBody;
        final client = MockClient((request) async {
          capturedBody = request.body;
          return http.Response(jsonEncode({'content': {}}), 201);
        });

        final service = GitHubService(crypto, client);
        await service.createOrUpdateFile(
          token: testToken,
          owner: 'user',
          repo: 'repo',
          path: 'notes/test.md',
          content: '# Hello',
          message: 'commit message',
        );

        final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(body['message'], 'commit message');
        expect(body['content'], isNot('# Hello'));
        expect(body.containsKey('sha'), isFalse);
      });

      test('includes sha when updating existing file', () async {
        String? capturedBody;
        final client = MockClient((request) async {
          capturedBody = request.body;
          return http.Response(jsonEncode({'content': {}}), 200);
        });

        final service = GitHubService(crypto, client);
        await service.createOrUpdateFile(
          token: testToken,
          owner: 'user',
          repo: 'repo',
          path: 'notes/test.md',
          content: 'Updated',
          message: 'update',
          sha: 'abc123sha',
        );

        final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(body['sha'], 'abc123sha');
      });

      test('throws on error response', () {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({'message': 'Not Found'}),
            404,
          );
        });

        final service = GitHubService(crypto, client);
        expect(
          () => service.createOrUpdateFile(
            token: testToken,
            owner: 'user',
            repo: 'repo',
            path: 'notes/test.md',
            content: 'data',
            message: 'msg',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getFile', () {
      test('returns content and sha when file exists', () async {
        final client = MockClient((request) async {
          final content = base64.encode(utf8.encode('# Test Note'));
          return http.Response(
            jsonEncode({
              'content': content,
              'sha': 'file_sha_123',
            }),
            200,
          );
        });

        final service = GitHubService(crypto, client);
        final result = await service.getFile(
          token: testToken,
          owner: 'user',
          repo: 'repo',
          path: 'notes/test.md',
        );

        expect(result, isNotNull);
        expect(result!.content, '# Test Note');
        expect(result.sha, 'file_sha_123');
      });

      test('returns null on 404', () async {
        final client = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final service = GitHubService(crypto, client);
        final result = await service.getFile(
          token: testToken,
          owner: 'user',
          repo: 'repo',
          path: 'notes/missing.md',
        );

        expect(result, isNull);
      });

      test('handles base64 content with newlines', () async {
        final client = MockClient((request) async {
          final content = base64.encode(utf8.encode('Line 1\nLine 2'));
          final withNewlines = content.replaceAll('', '\n');
          return http.Response(
            jsonEncode({
              'content': withNewlines,
              'sha': 'sha',
            }),
            200,
          );
        });

        final service = GitHubService(crypto, client);
        final result = await service.getFile(
          token: testToken,
          owner: 'user',
          repo: 'repo',
          path: 'notes/test.md',
        );

        expect(result, isNotNull);
        expect(result!.content, 'Line 1\nLine 2');
      });
    });

    group('deleteFile', () {
      test('sends delete request with sha', () async {
        String? capturedBody;
        final client = MockClient((request) async {
          capturedBody = request.body;
          expect(request.method, 'DELETE');
          return http.Response(jsonEncode({}), 200);
        });

        final service = GitHubService(crypto, client);
        await service.deleteFile(
          token: testToken,
          owner: 'user',
          repo: 'repo',
          path: 'notes/test.md',
          message: 'delete note',
          sha: 'file_sha',
        );

        final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(body['sha'], 'file_sha');
      });

      test('throws on error', () {
        final client = MockClient((request) async {
          return http.Response('Forbidden', 403);
        });

        final service = GitHubService(crypto, client);
        expect(
          () => service.deleteFile(
            token: testToken,
            owner: 'user',
            repo: 'repo',
            path: 'notes/test.md',
            message: 'delete',
            sha: 'sha',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('listFiles', () {
      test('returns files from directory', () async {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode([
              {'name': 'note1.md', 'path': 'notes/note1.md', 'sha': 'sha1', 'size': 100, 'type': 'file'},
              {'name': 'note2.md', 'path': 'notes/note2.md', 'sha': 'sha2', 'size': 200, 'type': 'file'},
              {'name': 'subdir', 'path': 'notes/subdir', 'sha': 'sha3', 'size': 0, 'type': 'dir'},
            ]),
            200,
          );
        });

        final service = GitHubService(crypto, client);
        final files = await service.listFiles(
          token: testToken,
          owner: 'user',
          repo: 'repo',
          path: 'notes',
        );

        expect(files.length, 2);
        expect(files[0].name, 'note1.md');
        expect(files[0].sha, 'sha1');
        expect(files[1].name, 'note2.md');
      });

      test('returns empty list on 404', () async {
        final client = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final service = GitHubService(crypto, client);
        final files = await service.listFiles(
          token: testToken,
          owner: 'user',
          repo: 'repo',
          path: 'notes',
        );

        expect(files, isEmpty);
      });
    });
  });
}
