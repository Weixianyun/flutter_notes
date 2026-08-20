import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/services/tag_metadata_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getTagColor returns default purple for unknown tags', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = TagMetadataService(prefs);

    expect(service.getTagColor('unknown'), TagMetadataService.presetColors.first);
  });

  test('setTagColor persists the color', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = TagMetadataService(prefs);

    await service.setTagColor('flutter', const Color(0xFF1976D2));
    expect(service.getTagColor('flutter'), const Color(0xFF1976D2));
  });

  test('removeTagColor resets to default', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = TagMetadataService(prefs);

    await service.setTagColor('flutter', const Color(0xFF1976D2));
    await service.removeTagColor('flutter');
    expect(service.getTagColor('flutter'), TagMetadataService.presetColors.first);
  });

  test('getAllTagColors returns the configured mapping', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = TagMetadataService(prefs);

    await service.setTagColor('a', const Color(0xFF111111));
    await service.setTagColor('b', const Color(0xFF222222));

    final colors = service.getAllTagColors();
    expect(colors['a'], const Color(0xFF111111));
    expect(colors['b'], const Color(0xFF222222));
  });

  test('corrupt data is ignored gracefully', () async {
    SharedPreferences.setMockInitialValues({
      'tag_colors': ['corrupted|entry|too|many|parts', 'valid|4280391411'],
    });
    final prefs = await SharedPreferences.getInstance();
    final service = TagMetadataService(prefs);

    final colors = service.getAllTagColors();
    expect(colors.length, 1);
    expect(colors['valid'], isA<Color>());
  });
}
