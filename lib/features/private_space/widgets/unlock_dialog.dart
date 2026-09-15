import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/biometric_authenticator.dart';
import '../../../core/services/private_space_store.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';
import '../controllers/private_space_controller.dart';

/// Asks for the Private space PIN, with the device biometric offered when it is enabled.
///
/// Returns true only when the space was actually unlocked, so a caller can gate entering
/// the grid on a real answer rather than on the dialog being dismissed.
Future<bool> showPrivateSpaceUnlockDialog(
  BuildContext context,
  PrivateSpaceController privateSpace, {
  String? title,
  String? message,
}) async {
  final String heading = title ?? context.l10n.unlockTitle;
  final bool? unlocked = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => _UnlockDialog(
      privateSpace: privateSpace,
      title: heading,
      message: message,
    ),
  );
  return unlocked ?? false;
}

class _UnlockDialog extends StatefulWidget {
  const _UnlockDialog({
    required this.privateSpace,
    required this.title,
    this.message,
  });

  final PrivateSpaceController privateSpace;
  final String title;
  final String? message;

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  final TextEditingController _pin = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    if (_pin.text.isEmpty || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final bool ok = await widget.privateSpace.unlockWithPin(_pin.text);
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = context.l10n.unlockIncorrectPin;
      _pin.clear();
    });
  }

  Future<void> _submitBiometric() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final BiometricResult result =
        await widget.privateSpace.unlockWithBiometric(
      reason: context.l10n.unlockBiometricReason,
    );
    if (!mounted) {
      return;
    }
    switch (result) {
      case BiometricResult.success:
        Navigator.of(context).pop(true);
      case BiometricResult.cancelled:
        setState(() => _busy = false);
      case BiometricResult.unavailable:
        setState(() {
          _busy = false;
          _error = context.l10n.unlockFingerprintUnavailable;
        });
      case BiometricResult.failed:
        setState(() {
          _busy = false;
          _error = context.l10n.unlockFingerprintNotRecognised;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool canUseBiometric = widget.privateSpace.biometricEnabled &&
        widget.privateSpace.biometricAvailable.value;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.message != null) ...<Widget>[
            Text(widget.message!),
            SizedBox(height: 14.h),
          ],
          TextField(
            controller: _pin,
            autofocus: true,
            enabled: !_busy,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: PrivateSpaceStore.maxPinLength,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: l10n.unlockPinLabel,
              counterText: '',
              errorText: _error,
            ),
            onSubmitted: (_) => _submitPin(),
          ),
          if (canUseBiometric) ...<Widget>[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _busy ? null : _submitBiometric,
                icon: const Icon(Icons.fingerprint),
                label: Text(l10n.unlockUseFingerprint),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submitPin,
          child: Text(l10n.unlockConfirm),
        ),
      ],
    );
  }
}
