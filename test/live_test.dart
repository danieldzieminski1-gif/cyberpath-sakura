import 'package:cyberpath/features/content/data/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('malformed remote data never throws and adds nothing', () {
    expect(parseRemoteCourses('not json'), isEmpty);
    expect(parseRemoteCourses('{"courses": 5}'), isEmpty);
    expect(parseRemoteCourses('{"courses":[{"id":"x","modules":[{"lessons":[{"id":"l"}]}]}]}'), isEmpty);
  });

  test('valid remote lessons merge once and local lessons stay intact', () {
    registerBonusContent();
    final before = kAllLessons.length;
    const json = '''
{"courses":[{"id":"modern2026","title":"t","modules":[{"id":"r1","title":"New","lessons":[
 {"id":"r-l1","title":"Remote","blocks":[
  {"type":"explanation","id":"r-b1","body":"hi"},
  {"type":"multipleChoice","id":"r-b2","body":"q","options":["a","b"],"answerIndex":1}
 ]}]}]}]}''';
    final added = mergeRemoteCourses(parseRemoteCourses(json));
    expect(added, 1);
    expect(kAllLessons.length, before + 1);
    expect(mergeRemoteCourses(parseRemoteCourses(json)), 0); // idempotent
  });

  test('bonus course has unique block ids and valid answers', () {
    registerBonusContent();
    final ids = <String>{};
    for (final l in courseById('modern2026')!.lessons) {
      for (final b in l.blocks) {
        expect(ids.add(b.id), isTrue);
        if (b.options.isNotEmpty) expect(b.answerIndex, inInclusiveRange(0, b.options.length - 1));
      }
    }
  });
}
