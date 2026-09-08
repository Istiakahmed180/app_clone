import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/status_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/space_identity.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../controllers/home_controller.dart';

/// Lets the user type this space's identifiers by hand.
///
/// Every field is free text. The screen refuses only what is structurally impossible —
/// a MAC with four octets, an Android ID that is not sixteen hex characters — and
/// *warns* about what is merely implausible, such as an IMEI whose check digit does not
/// add up. That split is the point: the user asked to set these values, and a value that
/// is detectably fabricated is their call to make, not something to block.
///
/// Pops `true` when something was saved.
class SpaceIdentityEditorView extends StatefulWidget {
  const SpaceIdentityEditorView({
    required this.controller,
    required this.profile,
    required this.identity,
    required this.spaceIndex,
    this.isRunning = false,
    super.key,
  });

  final HomeController controller;
  final VirtualProfileModel profile;
  final SpaceIdentity identity;
  final int spaceIndex;

  /// Whether the guest is running. A running app has already read whatever it reads.
  final bool isRunning;

  @override
  State<SpaceIdentityEditorView> createState() =>
      _SpaceIdentityEditorViewState();
}

class _SpaceIdentityEditorViewState extends State<SpaceIdentityEditorView> {
  late final Map<SpaceIdentifierField, TextEditingController> _fields =
      <SpaceIdentifierField, TextEditingController>{
        for (final SpaceIdentifierField field in SpaceIdentifierField.values)
          field: TextEditingController(text: field.read(widget.identity)),
      };

  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    for (final TextEditingController controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The first structural problem across all five fields, or null when there is none.
  String? get _blockingError {
    for (final SpaceIdentifierField field in SpaceIdentifierField.values) {
      final String? error = field.errorFor(_fields[field]!.text);
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  bool get _changed => SpaceIdentifierField.values.any(
    (SpaceIdentifierField field) =>
        _fields[field]!.text.trim() != field.read(widget.identity),
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Space ${widget.spaceIndex} identifiers')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: <Widget>[
          if (widget.isRunning) _runningNotice(theme),
          for (final SpaceIdentifierField field in SpaceIdentifierField.values)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: _field(theme, field),
            ),
          SizedBox(height: 12.h),
          if (_saveError != null) ...<Widget>[
            Text(
              _saveError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _restore,
                  child: const Text('Undo changes'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FilledButton(
                  onPressed: _saving || !_changed ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Says what a change will and will not do to a guest that is already running.
  Widget _runningNotice(ThemeData theme) {
    final Color colour = StatusColors.of(context).warning;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
        border: Border.all(color: colour.withValues(alpha: 0.4)),
        color: colour.withValues(alpha: 0.06),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 18.r, color: colour),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'This clone is running. An app reads its identifiers when it starts, so '
              'force stop the clone and open it again for a change to take effect.',
              style: theme.textTheme.bodySmall?.copyWith(color: colour),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(ThemeData theme, SpaceIdentifierField field) {
    final String value = _fields[field]!.text;
    final String? error = field.errorFor(value);
    final String? warning = error == null ? field.warningFor(value) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _fields[field],
          onChanged: (String _) => setState(() => _saveError = null),
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: <String>['Roboto Mono', 'Menlo', 'Courier'],
          ),
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            errorText: error,
            suffixIcon: IconButton(
              tooltip: 'Copy ${field.label}',
              icon: Icon(Icons.copy_outlined, size: 20.r),
              onPressed: () => _copy(field, value),
            ),
          ),
        ),
        if (warning != null)
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.warning_amber_outlined,
                  size: 14.r,
                  color: StatusColors.of(context).warning,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    warning,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: StatusColors.of(context).warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 12.h),
      ],
    );
  }

  void _restore() {
    setState(() {
      for (final SpaceIdentifierField field in SpaceIdentifierField.values) {
        _fields[field]!.text = field.read(widget.identity);
      }
      _saveError = null;
    });
  }

  Future<void> _save() async {
    final String? error = _blockingError;
    if (error != null) {
      setState(() => _saveError = error);
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await widget.controller.spaceIdentity(
        widget.profile,
        action: 'update',
        values: <String, String>{
          for (final SpaceIdentifierField field in SpaceIdentifierField.values)
            field.key: _fields[field]!.text.trim(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppException catch (failure) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = failure.message;
        });
      }
    }
  }

  Future<void> _copy(SpaceIdentifierField field, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${field.label} copied.')));
    }
  }
}

/// Confirms replacing a space's identifiers with a new random set.
///
/// Asked because it cannot be undone: the previous values are overwritten and kept
/// nowhere, so there is no route back to them.
Future<bool> showResetIdentityDialog(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Generate new identifiers?'),
      content: const Text(
        'This space will be given a new random device ID, Android ID, serial number '
        'and MAC addresses. The current ones are deleted and cannot be recovered. Apps '
        'in this clone may treat it as a new device and sign you out.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Generate'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
