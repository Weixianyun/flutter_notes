import 'package:flutter_notes/services/performance_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PerformanceMetric', () {
    test('fps getter returns null for startup metric', () {
      final metric = PerformanceMetric(
        kind: PerformanceMetricKind.startup,
        valueMs: 1200,
        recordedAt: DateTime(2026, 1, 1),
      );
      expect(metric.fps, isNull);
    });

    test('fps getter returns null for scroll with non-positive value', () {
      final metric = PerformanceMetric(
        kind: PerformanceMetricKind.scroll,
        valueMs: 0,
        recordedAt: DateTime(2026, 1, 1),
      );
      expect(metric.fps, isNull);
    });

    test('fps getter derives 1000/valueMs for scroll metric', () {
      final metric = PerformanceMetric(
        kind: PerformanceMetricKind.scroll,
        valueMs: 16.7,
        recordedAt: DateTime(2026, 1, 1),
      );
      expect(metric.fps, closeTo(59.88, 0.01));
    });

    test('toJson and fromJson round-trip', () {
      final original = PerformanceMetric(
        kind: PerformanceMetricKind.scroll,
        valueMs: 18.2,
        recordedAt: DateTime.utc(2026, 8, 22, 10, 30),
      );
      final restored = PerformanceMetric.fromJson(original.toJson());
      expect(restored, isNotNull);
      expect(restored!.kind, PerformanceMetricKind.scroll);
      expect(restored.valueMs, 18.2);
      expect(restored.recordedAt.toUtc(), DateTime.utc(2026, 8, 22, 10, 30));
    });

    test('fromJson returns null for missing fields', () {
      expect(PerformanceMetric.fromJson({'kind': 'startup'}), isNull);
      expect(PerformanceMetric.fromJson({'value': 1, 'at': 'now'}), isNull);
    });

    test('fromJson falls back kind to startup on unknown value', () {
      final restored = PerformanceMetric.fromJson({
        'kind': 'unknown_kind',
        'value': 50,
        'at': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(restored, isNotNull);
      expect(restored!.kind, PerformanceMetricKind.startup);
    });
  });

  group('PerformanceService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('enabled defaults to true and can be toggled', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PerformanceService(prefs);
      expect(service.enabled, isTrue);
      await service.setEnabled(false);
      expect(service.enabled, isFalse);
    });

    test('addMetric stores entries in reverse chronological order',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PerformanceService(prefs);
      await service.addMetric(PerformanceMetric(
        kind: PerformanceMetricKind.startup,
        valueMs: 1000,
        recordedAt: DateTime(2026, 1, 1, 10),
      ));
      await service.addMetric(PerformanceMetric(
        kind: PerformanceMetricKind.startup,
        valueMs: 800,
        recordedAt: DateTime(2026, 1, 1, 11),
      ));
      final metrics = service.getMetrics();
      expect(metrics.length, 2);
      expect(metrics.first.valueMs, 800);
      expect(metrics.last.valueMs, 1000);
    });

    test('addMetric caps storage at _maxRecords', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PerformanceService(prefs);
      for (var i = 0; i < PerformanceService.maxRecordsForTest + 5; i++) {
        await service.addMetric(PerformanceMetric(
          kind: PerformanceMetricKind.scroll,
          valueMs: i.toDouble(),
          recordedAt: DateTime(2026, 1, 1, 0, i),
        ));
      }
      final metrics = service.getMetrics();
      expect(metrics.length, PerformanceService.maxRecordsForTest);
    });

    test('addMetric is ignored when disabled', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PerformanceService(prefs);
      await service.setEnabled(false);
      await service.addMetric(PerformanceMetric(
        kind: PerformanceMetricKind.startup,
        valueMs: 500,
        recordedAt: DateTime(2026, 1, 1),
      ));
      expect(service.getMetrics(), isEmpty);
    });

    test('clear removes all stored records', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = PerformanceService(prefs);
      await service.addMetric(PerformanceMetric(
        kind: PerformanceMetricKind.scroll,
        valueMs: 16.0,
        recordedAt: DateTime(2026, 1, 1),
      ));
      expect(service.getMetrics(), isNotEmpty);
      await service.clear();
      expect(service.getMetrics(), isEmpty);
    });

    test('markProcessStart records current timestamp', () {
      PerformanceService.processStartMs = 0;
      PerformanceService.markProcessStart();
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(PerformanceService.processStartMs, lessThanOrEqualTo(now));
      expect(
        PerformanceService.processStartMs,
        greaterThan(now - 5000),
      );
    });

    test('getMetrics tolerates corrupt JSON', () async {
      SharedPreferences.setMockInitialValues({
        'performance_metrics': 'not-json',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = PerformanceService(prefs);
      expect(service.getMetrics(), isEmpty);
    });
  });
}
