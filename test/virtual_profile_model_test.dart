import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/data/models/platform_info.dart';
import 'package:duplika/data/models/test_app_model.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';

void main() {
  test('VirtualProfileModel survives a JSON round trip', () {
    final VirtualProfileModel profile = VirtualProfileModel(
      id: 'abc',
      packageName: 'com.example.virtualtestapp',
      appName: 'Virtual Test App',
      profileName: 'Profile 1',
      createdAt: DateTime.parse('2026-09-05T10:00:00.000'),
    );

    expect(VirtualProfileModel.fromJson(profile.toJson()), profile);
  });

  test('TestAppModel reports a not-installed result cleanly', () {
    final TestAppModel model = TestAppModel.fromMap(<String, dynamic>{
      'installed': false,
      'packageName': 'com.example.virtualtestapp',
    });

    expect(model.installed, isFalse);
    expect(model.appName, isNull);
    expect(model.displayName, 'com.example.virtualtestapp');
  });

  test('TestAppModel reads a full native payload', () {
    final TestAppModel model = TestAppModel.fromMap(<String, dynamic>{
      'installed': true,
      'packageName': 'com.example.virtualtestapp',
      'appName': 'Virtual Test App',
      'versionName': '1.0.0',
      'versionCode': '1',
    });

    expect(model.installed, isTrue);
    expect(model.displayName, 'Virtual Test App');
    expect(model.versionName, '1.0.0');
  });

  test('PlatformInfo falls back to placeholders for missing keys', () {
    final PlatformInfo info = PlatformInfo.fromMap(<String, dynamic>{});

    expect(info.sdkInt, 0);
    expect(info.summary, contains('unknown'));
  });
}
