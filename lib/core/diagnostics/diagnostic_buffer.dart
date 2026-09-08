import 'diagnostic_event.dart';

/// Fixed-capacity, oldest-out ring of recent events.
///
/// The console has to open instantly with something useful on screen, which rules out
/// reading the persistent log first. This is that instant answer. It is also the reason
/// logging is cheap: recording an event is an array write, and nothing else on the
/// calling path is synchronous.
///
/// Capacity is a hard bound, not a target — a runaway subsystem cannot grow this.
class DiagnosticBuffer {
  DiagnosticBuffer({this.capacity = defaultCapacity})
      : assert(capacity > 0, 'A ring buffer needs room for at least one event.'),
        _slots = List<DiagnosticEvent?>.filled(capacity, null);

  /// Chosen against the spec's 500–2000 window. 1000 events covers a full launch
  /// sequence with room to spare and costs well under a megabyte of heap.
  static const int defaultCapacity = 1000;

  final int capacity;
  final List<DiagnosticEvent?> _slots;

  int _next = 0;
  int _length = 0;

  /// How many events have ever been added, including ones that have since aged out.
  /// The console shows this so "500 events" is not mistaken for "500 events happened".
  int get totalRecorded => _totalRecorded;
  int _totalRecorded = 0;

  int get length => _length;

  bool get isEmpty => _length == 0;

  /// True once the buffer has started dropping events.
  bool get hasOverflowed => _totalRecorded > capacity;

  void add(DiagnosticEvent event) {
    _slots[_next] = event;
    _next = (_next + 1) % capacity;
    if (_length < capacity) {
      _length++;
    }
    _totalRecorded++;
  }

  void clear() {
    _slots.fillRange(0, capacity, null);
    _next = 0;
    _length = 0;
    _totalRecorded = 0;
  }

  /// Oldest first. Copied out, so a caller iterating the result cannot be tripped up
  /// by an event arriving mid-loop.
  List<DiagnosticEvent> toList() {
    final List<DiagnosticEvent> events = <DiagnosticEvent>[];
    final int start = _length < capacity ? 0 : _next;
    for (int offset = 0; offset < _length; offset++) {
      final DiagnosticEvent? event = _slots[(start + offset) % capacity];
      if (event != null) {
        events.add(event);
      }
    }
    return events;
  }
}
