import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/data/models/note_model.dart';
import 'package:flutter_notes/services/crypto_service.dart';
import 'package:flutter_notes/services/github_service.dart';
import 'package:flutter_notes/services/sync_service.dart';

void main() {
  late SharedPreferences prefs;
  late EncryptionService crypto;
  const testToken = 'ghp_test_token';
  const owner = 'testuser';
  const repo = 'my_notes';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    crypto = EncryptionService(prefs);
  });

  NoteModel createNote({
    String id = 'note-001',
    String title = 'Test Note',
    String content = 'Hello World',
    NotePriority priority = NotePriority.medium,
    NoteStatus status = NoteStatus.draft,
    List<String> tags = const ['tag1', 'tag2'],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id,
      title: title,
      content: content,
      priority: priority,
      status: status,
      tags: tags,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 1, 2),
    );
  }

  /// Helper: build MockClient that handles GitHub API endpoints
  http.Client buildMockClient({
    String? fileContent,
    String? fileSha,
    int fileStatus = 200,
    List<Map<String, dynamic>>? listFilesResponse,
    int listFilesStatus = 200,
    int putStatus = 201,
  }) {
    return MockClient((request) async {
      final url = request.url.toString();
      final method = request.method;

      // GET file (contents/{path})
      if (method == 'GET' && url.contains('/contents/notes/')) {
        if (fileStatus == 404) {
          return http.Response('Not Found', 404);
        }
        final content = base64.encode(utf8.encode(fileContent ?? ''));
        return http.Response(
          jsonEncode({
            'content': content,
            'sha': fileSha ?? 'file_sha_123',
          }),
          fileStatus,
        );
      }

      // PUT file (create or update)
      if (method == 'PUT' && url.contains('/contents/notes/')) {
        return http.Response(
          jsonEncode({'content': {'sha': 'new_sha'}}),
          putStatus,
        );
      }

      // GET directory listing
      if (method == 'GET' && url.contains('/contents/notes') &&
          !url.contains('/notes/')) {
        if (listFilesStatus == 404) {
          return http.Response('Not Found', 404);
        }
        return http.Response(
          jsonEncode(listFilesResponse ?? []),
          listFilesStatus,
        );
      }

      return http.Response('Not Found', 404);
    });
  }

  group('SyncService', () {
    group('noteToMarkdown', () {
      test('includes YAML front matter with all fields', () {
        final client = buildMockClient();
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final note = createNote();
        final md = sync.noteToMarkdown(note);

        expect(md, contains('---'));
        expect(md, contains('id: note-001'));
        expect(md, contains('title: Test Note'));
        expect(md, contains('priority: medium'));
        expect(md, contains('status: draft'));
        expect(md, contains('tags: [tag1, tag2]'));
        expect(md, contains('created_at: 2026-01-01'));
        expect(md, contains('updated_at: 2026-01-02'));
        expect(md, contains('Hello World'));
      });

      test('uses placeholder for empty content', () {
        final client = buildMockClient();
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final note = createNote(content: '');
        final md = sync.noteToMarkdown(note);

        expect(md, contains('*暂无内容*'));
      });
    });

    group('slugify', () {
      test('converts spaces to hyphens', () {
        final client = buildMockClient();
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        expect(sync.slugify('Hello World'), 'hello-world');
      });

      test('removes special characters', () {
        final client = buildMockClient();
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        expect(sync.slugify('Hello! @World #123'), 'hello-world-123');
      });

      test('converts to lowercase', () {
        final client = buildMockClient();
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        expect(sync.slugify('HELLO'), 'hello');
      });

      test('preserves Chinese characters', () {
        final client = buildMockClient();
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        expect(sync.slugify('你好 World'), '你好-world');
      });

      test('truncates to 50 characters', () {
        final client = buildMockClient();
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final longTitle = 'A' * 100;
        final result = sync.slugify(longTitle);
        expect(result.length, lessThanOrEqualTo(50));
      });
    });

    group('pushNote', () {
      test('creates new file when not exists', () async {
        String? capturedBody;
        final client = MockClient((request) async {
          if (request.method == 'GET' && request.url.toString().contains('/contents/notes/')) {
            return http.Response('Not Found', 404);
          }
          if (request.method == 'PUT') {
            capturedBody = request.body;
            return http.Response(jsonEncode({'content': {}}), 201);
          }
          return http.Response('', 500);
        });

        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        await sync.pushNote(
          owner: owner,
          repo: repo,
          note: createNote(),
        );

        final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(body['message'], 'sync: Test Note');
        expect(body.containsKey('sha'), isFalse);
      });

      test('updates existing file with sha', () async {
        String? capturedBody;
        final client = MockClient((request) async {
          if (request.method == 'GET' && request.url.toString().contains('/contents/notes/')) {
            final content = base64.encode(utf8.encode('old content'));
            return http.Response(
              jsonEncode({'content': content, 'sha': 'existing_sha'}),
              200,
            );
          }
          if (request.method == 'PUT') {
            capturedBody = request.body;
            return http.Response(jsonEncode({'content': {}}), 200);
          }
          return http.Response('', 500);
        });

        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        await sync.pushNote(
          owner: owner,
          repo: repo,
          note: createNote(),
        );

        final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(body['sha'], 'existing_sha');
      });

      test('uses note id as filename when title is empty', () async {
        String? capturedUrl;
        final client = MockClient((request) async {
          capturedUrl = request.url.toString();
          if (request.method == 'GET') return http.Response('Not Found', 404);
          if (request.method == 'PUT') return http.Response(jsonEncode({}), 201);
          return http.Response('', 500);
        });

        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        await sync.pushNote(
          owner: owner,
          repo: repo,
          note: createNote(title: '', id: 'abc-123'),
        );

        expect(capturedUrl, contains('notes/abc-123.md'));
      });
    });

    group('pushAllNotes', () {
      test('returns success result when all notes pushed', () async {
        final client = buildMockClient(fileStatus: 404, putStatus: 201);
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final notes = [
          createNote(id: 'n1', title: 'Note 1'),
          createNote(id: 'n2', title: 'Note 2'),
          createNote(id: 'n3', title: 'Note 3'),
        ];

        final result = await sync.pushAllNotes(
          owner: owner,
          repo: repo,
          notes: notes,
        );

        expect(result.total, 3);
        expect(result.success, 3);
        expect(result.failed, 0);
        expect(result.errors, isEmpty);
        expect(result.isSuccess, isTrue);
      });

      test('collects errors for failed notes', () async {
        final client = MockClient((request) async {
          if (request.method == 'GET') return http.Response('Not Found', 404);
          if (request.method == 'PUT') {
            return http.Response(
              jsonEncode({'message': 'Rate limited'}),
              403,
            );
          }
          return http.Response('', 500);
        });

        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final result = await sync.pushAllNotes(
          owner: owner,
          repo: repo,
          notes: [createNote(id: 'n1', title: 'Note 1')],
        );

        expect(result.total, 1);
        expect(result.success, 0);
        expect(result.failed, 1);
        expect(result.errors, isNotEmpty);
        expect(result.isSuccess, isFalse);
      });

      test('handles partial success', () async {
        var callCount = 0;
        final client = MockClient((request) async {
          if (request.method == 'GET') return http.Response('Not Found', 404);
          if (request.method == 'PUT') {
            callCount++;
            if (callCount == 2) {
              return http.Response(jsonEncode({'message': 'error'}), 500);
            }
            return http.Response(jsonEncode({}), 201);
          }
          return http.Response('', 500);
        });

        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final result = await sync.pushAllNotes(
          owner: owner,
          repo: repo,
          notes: [
            createNote(id: 'n1', title: 'Note 1'),
            createNote(id: 'n2', title: 'Note 2'),
          ],
        );

        expect(result.total, 2);
        expect(result.success, 1);
        expect(result.failed, 1);
      });
    });

    group('pullNotes', () {
      test('returns parsed notes from remote', () async {
        final noteMd = '''---
id: remote-001
title: Remote Note
priority: high
status: published
tags: [remote, sync]
created_at: 2026-02-01T10:00:00.000
updated_at: 2026-02-02T12:00:00.000
---

This is remote content.''';

        final listResponse = [
          {'name': 'remote-note.md', 'path': 'notes/remote-note.md', 'sha': 'sha1', 'size': 100, 'type': 'file'},
        ];

        final client = MockClient((request) async {
          final url = request.url.toString();
          if (request.method == 'GET' && url.contains('/contents/notes/')) {
            final content = base64.encode(utf8.encode(noteMd));
            return http.Response(
              jsonEncode({'content': content, 'sha': 'sha1'}),
              200,
            );
          }
          if (request.method == 'GET' && url.contains('/contents/notes')) {
            return http.Response(jsonEncode(listResponse), 200);
          }
          return http.Response('', 404);
        });

        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final notes = await sync.pullNotes(owner: owner, repo: repo);

        expect(notes.length, 1);
        expect(notes[0].id, 'remote-001');
        expect(notes[0].title, 'Remote Note');
        expect(notes[0].priority, NotePriority.high);
        expect(notes[0].status, NoteStatus.published);
        expect(notes[0].tags, ['remote', 'sync']);
        expect(notes[0].content, 'This is remote content.');
      });

      test('returns empty list when no notes directory', () async {
        final client = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final notes = await sync.pullNotes(owner: owner, repo: repo);
        expect(notes, isEmpty);
      });

      test('skips non-markdown files', () async {
        final listResponse = [
          {'name': 'note.md', 'path': 'notes/note.md', 'sha': 'sha1', 'size': 50, 'type': 'file'},
          {'name': 'image.png', 'path': 'notes/image.png', 'sha': 'sha2', 'size': 500, 'type': 'file'},
        ];

        final client = MockClient((request) async {
          final url = request.url.toString();
          if (request.method == 'GET' && url.contains('/contents/notes/')) {
            final md = '''---
id: n1
title: T
priority: medium
status: draft
tags: []
created_at: 2026-01-01T00:00:00.000
updated_at: 2026-01-01T00:00:00.000
---

Content''';
            return http.Response(
              jsonEncode({'content': base64.encode(utf8.encode(md)), 'sha': 's'}),
              200,
            );
          }
          if (request.method == 'GET' && url.contains('/contents/notes')) {
            return http.Response(jsonEncode(listResponse), 200);
          }
          return http.Response('', 404);
        });

        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final notes = await sync.pullNotes(owner: owner, repo: repo);
        expect(notes.length, 1);
      });
    });

    group('syncWithConflictCheck', () {
      test('pushes local note when remote does not exist', () async {
        final client = buildMockClient(fileStatus: 404, putStatus: 201);
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final localNotes = [
          createNote(id: 'local-1', title: 'Local Only'),
        ];

        final result = await sync.syncWithConflictCheck(
          owner: owner,
          repo: repo,
          localNotes: localNotes,
          remoteNotes: [],
          resolution: ConflictResolution.localWins,
        );

        expect(result.success, 1);
        expect(result.skipped, 0);
      });

      test('pushes when local is newer', () async {
        final client = buildMockClient(fileStatus: 200, fileContent: 'old', fileSha: 'sha', putStatus: 200);
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final localNotes = [
          createNote(
            id: 'shared-1',
            updatedAt: DateTime(2026, 3, 1),
          ),
        ];
        final remoteNotes = [
          createNote(
            id: 'shared-1',
            updatedAt: DateTime(2026, 2, 1),
          ),
        ];

        final result = await sync.syncWithConflictCheck(
          owner: owner,
          repo: repo,
          localNotes: localNotes,
          remoteNotes: remoteNotes,
          resolution: ConflictResolution.localWins,
        );

        expect(result.success, 1);
        expect(result.skipped, 0);
      });

      test('skips when remote is newer and resolution is skip', () async {
        final client = buildMockClient(fileStatus: 200, fileContent: 'old', fileSha: 'sha');
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final localNotes = [
          createNote(id: 'shared-1', updatedAt: DateTime(2026, 2, 1)),
        ];
        final remoteNotes = [
          createNote(id: 'shared-1', updatedAt: DateTime(2026, 3, 1)),
        ];

        final result = await sync.syncWithConflictCheck(
          owner: owner,
          repo: repo,
          localNotes: localNotes,
          remoteNotes: remoteNotes,
          resolution: ConflictResolution.skip,
        );

        expect(result.success, 0);
        expect(result.skipped, 1);
      });

      test('pushes local when remote is newer but resolution is localWins', () async {
        final client = buildMockClient(fileStatus: 200, fileContent: 'old', fileSha: 'sha', putStatus: 200);
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final localNotes = [
          createNote(id: 'shared-1', updatedAt: DateTime(2026, 2, 1)),
        ];
        final remoteNotes = [
          createNote(id: 'shared-1', updatedAt: DateTime(2026, 3, 1)),
        ];

        final result = await sync.syncWithConflictCheck(
          owner: owner,
          repo: repo,
          localNotes: localNotes,
          remoteNotes: remoteNotes,
          resolution: ConflictResolution.localWins,
        );

        expect(result.success, 1);
      });

      test('skips when timestamps are equal', () async {
        final client = buildMockClient();
        final github = GitHubService(crypto, client);
        final sync = SyncService(github, testToken);

        final time = DateTime(2026, 1, 1, 12, 0);
        final localNotes = [createNote(id: 'shared-1', updatedAt: time)];
        final remoteNotes = [createNote(id: 'shared-1', updatedAt: time)];

        final result = await sync.syncWithConflictCheck(
          owner: owner,
          repo: repo,
          localNotes: localNotes,
          remoteNotes: remoteNotes,
          resolution: ConflictResolution.localWins,
        );

        expect(result.success, 0);
        expect(result.skipped, 1);
      });
    });

    group('SyncResult', () {
      test('isSuccess is true when no errors', () {
        const result = SyncResult(total: 5, success: 5, errors: []);
        expect(result.isSuccess, isTrue);
        expect(result.failed, 0);
      });

      test('isSuccess is false when errors exist', () {
        const result = SyncResult(total: 5, success: 3, errors: ['err1', 'err2']);
        expect(result.isSuccess, isFalse);
        expect(result.failed, 2);
      });

      test('skipped does not count as failed', () {
        const result = SyncResult(total: 5, success: 3, errors: [], skipped: 2);
        expect(result.failed, 0);
        expect(result.skipped, 2);
      });
    });
  });
}
