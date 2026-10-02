import 'package:flutter_test/flutter_test.dart';
import 'package:perform_plus/core/utils/reg_number.dart';

void main() {
  group('futoRegNumberFormat', () {
    test('extracts the entry year from a real-shape FUTO reg number', () {
      expect(futoRegNumberFormat.extractEntryYear('20211258122'), 2021);
    });

    test('matches the 11-digit no-separator shape', () {
      expect(futoRegNumberFormat.matches('20211258122'), isTrue);
      expect(futoRegNumberFormat.matches('21/ENG/12345'), isFalse);
    });

    test('extraction returns null when there are fewer than 4 digits', () {
      expect(futoRegNumberFormat.extractEntryYear('12'), isNull);
    });
  });

  group('genericRegNumberFormat', () {
    test('never blocks a real-looking reg number in either common shape', () {
      expect(genericRegNumberFormat.matches('21/ENG/12345'), isTrue);
      expect(genericRegNumberFormat.matches('20211258122'), isTrue);
    });

    test('blocks an obviously-too-short value', () {
      expect(genericRegNumberFormat.matches('12'), isFalse);
    });
  });
}
