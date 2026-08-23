import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_notes/features/editor/widgets/markdown_preview.dart';

void main() {
  group('handleLinkTap - 纯函数', () {
    test('null href → false，不调用任何回调', () {
      String? wikiTarget;
      String? attId;
      final r = handleLinkTap(
        href: null,
        onWikiLinkTap: (t, h) => wikiTarget = t,
        onAttachmentTap: (id, name) => attId = id,
      );
      expect(r, isFalse);
      expect(wikiTarget, isNull);
      expect(attId, isNull);
    });

    test('wiki-link → true 且调 onWikiLinkTap', () {
      String? target;
      String? heading;
      final r = handleLinkTap(
        href: '#wiki:My%20Note?h=Sec1',
        onWikiLinkTap: (t, h) {
          target = t;
          heading = h;
        },
        onAttachmentTap: (id, name) {},
      );
      expect(r, isTrue);
      expect(target, 'My Note');
      expect(heading, 'Sec1');
    });

    test('attachment://<id> → true 且调 onAttachmentTap', () {
      String? id;
      String? name;
      final r = handleLinkTap(
        href: 'attachment://abc-123?name=hello.png',
        onWikiLinkTap: (t, h) {},
        onAttachmentTap: (aId, aName) {
          id = aId;
          name = aName;
        },
      );
      expect(r, isTrue);
      expect(id, 'abc-123');
      expect(name, 'hello.png');
    });

    test('attachment://<id> 不带 name → name 为 null', () {
      String? id;
      String? name;
      handleLinkTap(
        href: 'attachment://abc-123',
        onWikiLinkTap: (t, h) {},
        onAttachmentTap: (aId, aName) {
          id = aId;
          name = aName;
        },
      );
      expect(id, 'abc-123');
      expect(name, isNull);
    });

    test('http 外链 → false（交给调用方默认行为）', () {
      String? id;
      final r = handleLinkTap(
        href: 'https://example.com',
        onWikiLinkTap: (t, h) {},
        onAttachmentTap: (aId, aName) => id = aId,
      );
      expect(r, isFalse);
      expect(id, isNull);
    });
  });
}
