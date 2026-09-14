import 'package:duplika/core/errors/app_exception.dart';
import 'package:duplika/data/models/background_activity_state.dart';
import 'package:duplika/data/models/battery_prompt_screen.dart';
import 'package:duplika/native/native_bridge.dart';

/// The background-activity calls answered from fields instead of a platform channel, with
/// the calls counted.
///
/// The three behaviours worth asserting are all here: what the platform reports ([state]),
/// which screen a tap asked for ([prompts] against [opened]), and what a device that
/// cannot answer does ([openFails], [promptFails]).
class FakeBackgroundActivityBridge extends NativeBridge {
  BackgroundActivityState? state;
  int opened = 0;
  int prompts = 0;
  bool openFails = false;
  bool promptFails = false;
  BatteryPromptScreen promptScreen = BatteryPromptScreen.dialog;

  @override
  Future<BackgroundActivityState?> backgroundActivityState() async => state;

  @override
  Future<BatteryPromptScreen> requestIgnoreBatteryOptimizations() async {
    if (promptFails) {
      throw const VirtualizationException(
        'no battery screen',
        code: 'BATTERY_PROMPT_UNAVAILABLE',
      );
    }
    prompts += 1;
    return promptScreen;
  }

  @override
  Future<BackgroundActivityScreen> openBackgroundActivitySettings() async {
    if (openFails) {
      throw const VirtualizationException(
        'no screen can handle it',
        code: 'NO_ACTIVITY',
      );
    }
    opened += 1;
    return BackgroundActivityScreen.appInfo;
  }
}
