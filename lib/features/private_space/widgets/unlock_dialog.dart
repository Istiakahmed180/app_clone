import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/biometric_authenticator.dart';
import '../../../core/services/private_space_store.dart';
import '../controllers/private_space_controller.dart';

/// Asks for the Private space PIN, with the device biometric offered when it is enabled.
///
/// Returns true only when the space was actually unlocked, so a caller can gate entering
/// the grid on a real answer rather than on the dialog being dismissed.
Future<bool> showPrivateSpaceUnlockDialog(
  BuildContext context,
  PrivateSpaceController privateSpace, {
  String title = 'Unlock Private space',
  String? message,
}) async {
  final bool? unlocked = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => _UnlockDialog(
      privateSpace: privateSpace,
      title: title,
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
      _error = 'Incorrect PIN';
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
        await widget.privateSpace.unlockWithBiometric();
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
          _error = 'Fingerprint unlock is not available right now.';
        });
      case BiometricResult.failed:
        setState(() {
          _busy = false;
          _error = 'Fingerprint not recognised.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              labelText: 'PIN',
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
                label: const Text('Use fingerprint'),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submitPin,
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
