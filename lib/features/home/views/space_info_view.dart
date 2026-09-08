import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/status_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/space_identity.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../controllers/home_controller.dart';
import 'space_identity_editor_view.dart';

/// The device identifiers one space presents as its own.
///
/// A page rather than a sheet because the identifier rows are meant to be read and
/// copied rather than glanced at.
///
/// The values are real stored per-space values and Modify/Reset really change them, but
/// a guest app does not read them yet: Bcore exposes no way to point its identifier
/// hooks at a per-space store. This screen therefore does not tell the user their
/// identifiers are isolated — see [SpaceIdentity.isolatedFromGuests] and the Space
/// identity section of `docs/ARCHITECTURE.md`.
class SpaceInfoView extends StatefulWidget {
  const SpaceInfoView({
    required this.controller,
    required this.profile,
    required this.state,
    this.instanceIndex = 1,
    this.engineActive = true,
    super.key,
  });

  final HomeController controller;
  final VirtualProfileModel profile;
  final VirtualProfileState state;
  final int instanceIndex;
  final bool engineActive;

  @override
  State<SpaceInfoView> createState() => _SpaceInfoViewState();
}

class _SpaceInfoViewState extends State<SpaceInfoView> {
  SpaceIdentity? _identity;
  String? _identityError;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String action = 'read'}) async {
    setState(() => _busy = true);
    try {
      final SpaceIdentity identity = await widget.controller.spaceIdentity(
        widget.profile,
        action: action,
      );
      if (mounted) {
        setState(() {
          _identity = identity;
          _identityError = null;
          _busy = false;
        });
      }
    } on AppException catch (error) {
      if (mounted) {
        setState(() {
          _identityError = error.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Space Info')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: <Widget>[
          _headerCard(theme),
          SizedBox(height: 22.h),
          Text('Device identifiers', style: theme.textTheme.titleMedium),
          SizedBox(height: 10.h),
          _identifierCard(theme),
          SizedBox(height: 20.h),
          _identityActions(theme),
        ],
      ),
    );
  }

  Widget _headerCard(ThemeData theme) {
    final ({String label, Color color}) status = _status(theme);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: <Widget>[
            Container(
              width: 60.r,
              height: 60.r,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 30.r,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Space ${widget.instanceIndex}',
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: <Widget>[
                      Icon(Icons.circle, size: 9.r, color: status.color),
                      SizedBox(width: 6.w),
                      // Flexible, not fixed: 'Rebuilds on launch' beside the ID pill is
                      // already wider than a narrow phone at a large font scale, and a
                      // status that wraps beats one that is clipped.
                      Flexible(
                        child: Text(
                          status.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: status.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // The space's own number, the way the user counts spaces. Deliberately not
            // the engine's container id: that is zero-based, so it read 'ID 0' beside
            // 'Space 1'.
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Text(
                'ID ${widget.instanceIndex}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String label, Color color}) _status(ThemeData theme) {
    if (!widget.engineActive) {
      return (label: 'Engine unavailable', color: theme.colorScheme.error);
    }
    if (widget.state.running) {
      return (label: 'Running', color: theme.colorScheme.primary);
    }
    if (widget.state.installed) {
      return (label: 'Active', color: StatusColors.of(context).positive);
    }
    return (label: 'Rebuilds on launch', color: theme.colorScheme.outline);
  }

  Widget _identifierCard(ThemeData theme) {
    if (_busy && _identity == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final SpaceIdentity? identity = _identity;
    if (identity == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            _identityError ??
                'This space has no container yet, so it has no identifiers. Launch it '
                    'once and they will appear here.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    final List<(IconData, String, String)> rows = <(IconData, String, String)>[
      (Icons.smartphone_outlined, 'Device ID', identity.deviceId),
      (Icons.fingerprint, 'Android ID', identity.androidId),
      (Icons.tag, 'Serial number', identity.serialNumber),
      (Icons.wifi, 'Wi-Fi MAC', identity.wifiMac),
      (Icons.bluetooth, 'Bluetooth MAC', identity.bluetoothMac),
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        child: Column(
          children: <Widget>[
            for (int index = 0; index < rows.length; index++) ...<Widget>[
              if (index > 0) const Divider(height: 1),
              _IdentifierRow(
                icon: rows[index].$1,
                label: rows[index].$2,
                value: rows[index].$3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _identityActions(ThemeData theme) {
    final bool enabled = _identity != null && !_busy;

    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton(
            onPressed: enabled ? _modify : null,
            child: const Text('Modify'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton(
            onPressed: enabled ? _reset : null,
            child: const Text('Reset'),
          ),
        ),
      ],
    );
  }

  /// Opens the editor, where each identifier is typed by hand.
  Future<void> _modify() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => SpaceIdentityEditorView(
          controller: widget.controller,
          profile: widget.profile,
          identity: _identity!,
          spaceIndex: widget.instanceIndex,
          isRunning: widget.state.running,
        ),
      ),
    );
    if (saved != true || !mounted) {
      return;
    }
    await _load();
    if (mounted) {
      _say('This space\'s identifiers were changed.');
    }
  }

  /// Replaces the whole set with new random values, after asking.
  ///
  /// Asked because it is irreversible: the previous values are overwritten and kept
  /// nowhere, so "undo" is not a thing that can be offered afterwards.
  Future<void> _reset() async {
    if (!await showResetIdentityDialog(context) || !mounted) {
      return;
    }
    await _load(action: 'regenerate');
    if (!mounted) {
      return;
    }
    _say('This space was given a new set of identifiers.');
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// One identifier: icon, label, value, and a way to get it out of the app.
class _IdentifierRow extends StatelessWidget {
  const _IdentifierRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: <Widget>[
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Icon(icon, size: 18.r, color: theme.colorScheme.primary),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2.h),
                // Selectable as well as copyable: a long identifier is often wanted in
                // part, and monospaced so digits line up between rows.
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: <String>[
                      'Roboto Mono',
                      'Menlo',
                      'Courier',
                    ],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy $label',
            icon: Icon(Icons.copy_outlined, size: 20.r),
            onPressed: () => _copy(context),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$label copied.')));
    }
  }
}
