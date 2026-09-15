import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/private_space_store.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';
import '../controllers/private_space_controller.dart';

enum PrivateSpaceSetupMode {
  /// First time: choose a PIN and turn the lock on.
  create,

  /// Change the existing PIN, confirming the current one first.
  change,
}

/// Sets or changes the Private space PIN.
class PrivateSpaceSetupView extends StatefulWidget {
  const PrivateSpaceSetupView({
    required this.privateSpace,
    required this.mode,
    super.key,
  });

  final PrivateSpaceController privateSpace;
  final PrivateSpaceSetupMode mode;

  @override
  State<PrivateSpaceSetupView> createState() => _PrivateSpaceSetupViewState();
}

class _PrivateSpaceSetupViewState extends State<PrivateSpaceSetupView> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _useBiometric = false;
  bool _busy = false;
  String? _error;

  bool get _isCreate => widget.mode == PrivateSpaceSetupMode.create;

  @override
  void initState() {
    super.initState();
    _useBiometric = widget.privateSpace.biometricAvailable.value;
  }

  @override
  void dispose() {
    _current.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final String pin = _pin.text;
    if (!PrivateSpaceStore.isValidPin(pin)) {
      setState(
        () => _error = l10n.pinLengthError(
          PrivateSpaceStore.minPinLength,
          PrivateSpaceStore.maxPinLength,
        ),
      );
      return;
    }
    if (pin != _confirm.text) {
      setState(() => _error = l10n.pinMismatchError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    if (_isCreate) {
      await widget.privateSpace.create(pin, useBiometric: _useBiometric);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    final bool changed = await widget.privateSpace.changePin(
      currentPin: _current.text,
      newPin: pin,
    );
    if (!mounted) {
      return;
    }
    if (!changed) {
      setState(() {
        _busy = false;
        _error = l10n.pinCurrentIncorrect;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreate ? l10n.pinCreateTitle : l10n.pinChangeTitle),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
        children: <Widget>[
          Text(
            _isCreate ? l10n.pinCreateMessage : l10n.pinChangeMessage,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: 20.h),
          if (!_isCreate) ...<Widget>[
            _field(
              controller: _current,
              label: l10n.pinCurrentLabel,
              autofocus: true,
            ),
            SizedBox(height: 14.h),
          ],
          _field(
            controller: _pin,
            label: l10n.pinNewLabel,
            autofocus: _isCreate,
          ),
          SizedBox(height: 14.h),
          _field(
            controller: _confirm,
            label: l10n.pinConfirmLabel,
          ),
          if (_error != null) ...<Widget>[
            SizedBox(height: 12.h),
            Text(
              _error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          if (_isCreate && widget.privateSpace.biometricAvailable.value) ...<Widget>[
            SizedBox(height: 8.h),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _useBiometric,
              onChanged: _busy
                  ? null
                  : (bool value) => setState(() => _useBiometric = value),
              title: Text(l10n.privateSpaceFingerprint),
              subtitle: Text(l10n.privateSpaceFingerprintAvailable),
            ),
          ],
          SizedBox(height: 24.h),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_isCreate ? l10n.pinCreateConfirm : l10n.pinSaveConfirm),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      enabled: !_busy,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: PrivateSpaceStore.maxPinLength,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }
}
