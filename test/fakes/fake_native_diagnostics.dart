import 'package:duplika/core/diagnostics/diagnostic_event.dart';
import 'package:duplika/core/diagnostics/native_diagnostics.dart';
import 'package:duplika/core/diagnostics/system_info.dart';

/// A native side that answers from a map instead of a platform channel.
///
/// [fails] is what a device that cannot answer looks like: the call throws rather than
/// returning something the app would report as a fact.
class FakeNativeDiagnostics extends NativeDiagnostics {
  FakeNativeDiagnostics({this.payload = const <String, dynamic>{}});

  Map<String, dynamic> payload;
  bool fails = false;

  @override
  Future<List<DiagnosticEvent>> readHistory({int limit = 2000}) async =>
      const <DiagnosticEvent>[];

  @override
  Future<SystemInfoSnapshot> systemInfo() async {
    if (fails) {
      throw StateError('channel is not answering');
    }
    return SystemInfoSnapshot.from(payload);
  }
}
