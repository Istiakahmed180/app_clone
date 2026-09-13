import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/core/diagnostics/system_info.dart';

/// The System Information report is read by a developer triaging someone else's device,
/// so what it says has to be unambiguous without the reader having the code in front of
/// them. These cover the parts that are easy to misread.
void main() {
  SystemInfoSnapshot snapshotOf(Map<String, dynamic> native) =>
      SystemInfoSnapshot.from(native);

  List<SystemInfoField> section(SystemInfoSnapshot snapshot, String title) =>
      snapshot
          .sections()
          .firstWhere((SystemInfoSection s) => s.title == title)
          .fields;

  String valueOf(
    SystemInfoSnapshot snapshot,
    String sectionTitle,
    String label,
  ) => section(
    snapshot,
    sectionTitle,
  ).firstWhere((SystemInfoField f) => f.label == label).value;

  group('memory', () {
    test('RAM is given as a round figure and an exact one', () {
      final SystemInfoSnapshot snapshot = snapshotOf(<String, dynamic>{
        'totalMemBytes': 8127352832,
        'availMemBytes': 2147483648,
      });

      // The round half is what a person reads; the exact half is what makes two
      // reports from two devices comparable.
      expect(
        valueOf(snapshot, 'Memory', 'Total RAM'),
        '7.6 GB (8127352832 bytes)',
      );
      expect(
        valueOf(snapshot, 'Memory', 'Available RAM'),
        '2.0 GB (2147483648 bytes)',
      );
    });

    test('a full volume reads zero, which is an answer, not a gap', () {
      final SystemInfoSnapshot snapshot = snapshotOf(<String, dynamic>{
        'internalFreeBytes': 0,
      });

      // The case the storage half of the report exists for. Calling it 'unknown' would
      // hide the one reading that explains why an install just failed.
      expect(valueOf(snapshot, 'Storage', 'Internal free'), '0 bytes');
    });

    test('small figures are not printed twice', () {
      final SystemInfoSnapshot snapshot = snapshotOf(<String, dynamic>{
        'internalFreeBytes': 512,
      });

      expect(valueOf(snapshot, 'Storage', 'Internal free'), '512 bytes');
    });

    test('a negative figure is no answer at all', () {
      final SystemInfoSnapshot snapshot = snapshotOf(<String, dynamic>{
        'totalMemBytes': -1,
      });

      expect(valueOf(snapshot, 'Memory', 'Total RAM'), 'unavailable');
    });

    test('a device that did not answer says so rather than reporting zero', () {
      final SystemInfoSnapshot snapshot = snapshotOf(<String, dynamic>{});

      // '0 bytes' would read as a finding. It is not one: nothing was measured.
      expect(valueOf(snapshot, 'Memory', 'Total RAM'), 'unavailable');
      expect(valueOf(snapshot, 'Memory', 'Low-RAM device'), 'unavailable');
    });

    test('the manufacturer\'s low-RAM declaration is carried through', () {
      final SystemInfoSnapshot snapshot = snapshotOf(<String, dynamic>{
        'isLowRamDevice': true,
        'underMemoryPressure': false,
      });

      expect(valueOf(snapshot, 'Memory', 'Low-RAM device'), 'true');
      expect(valueOf(snapshot, 'Memory', 'Under memory pressure'), 'false');
    });
  });

  group('multi-user context', () {
    test("Android's user cap is labelled as the host's, not the engine's", () {
      final SystemInfoSnapshot snapshot = snapshotOf(<String, dynamic>{
        'virtualUserIds': <int>[0, 1, 2],
        'hostSupportsMultipleUsers': false,
        'hostMaxAndroidUsers': 1,
      });

      // The trap this labelling exists to avoid: a device that permits one Android user
      // still holds as many containers as there is room for, because the engine numbers
      // its own. A reader must not take 1 for the clone ceiling when 3 are listed.
      expect(
        valueOf(snapshot, 'Virtualization engine', 'Host max Android users'),
        '1',
      );
      expect(
        valueOf(snapshot, 'Virtualization engine', 'Host multi-user support'),
        'false',
      );
      expect(
        valueOf(snapshot, 'Virtualization engine', 'Virtual users'),
        '0, 1, 2',
      );
    });

    test('no virtual users says so rather than rendering an empty row', () {
      final SystemInfoSnapshot snapshot = snapshotOf(<String, dynamic>{
        'virtualUserIds': <int>[],
      });

      // A blank value looks like a field that failed to render, which sends a reader
      // hunting for a bug in the report instead of reading the finding.
      expect(
        valueOf(snapshot, 'Virtualization engine', 'Virtual users'),
        'none',
      );
    });

    test('an unreadable cap is unavailable, not unlimited', () {
      final SystemInfoSnapshot snapshot = snapshotOf(<String, dynamic>{});

      expect(
        valueOf(snapshot, 'Virtualization engine', 'Host max Android users'),
        'unavailable',
      );
    });
  });

  test('the text export carries the new sections', () {
    final String report = snapshotOf(<String, dynamic>{
      'totalMemBytes': 4294967296,
      'hostMaxAndroidUsers': 4,
    }).toReportText();

    expect(report, contains('MEMORY'));
    expect(report, contains('4.0 GB (4294967296 bytes)'));
    expect(report, contains('Host max Android users'));
  });
}
