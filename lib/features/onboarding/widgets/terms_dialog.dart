import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/legal_constants.dart';
import '../../../core/utils/app_logger.dart';

/// First-launch terms and data-collection disclosure.
///
/// Non-dismissible: the two buttons are the only ways out, because "accepted" and "closed
/// the dialog" must not be the same event. Declining is a real option and closes the app.
///
/// The disclosure below states what Duplika actually collects today. It is the text the
/// user is agreeing to, so it must be kept true as the app changes -- not aspirational,
/// and not copied from another product.
class TermsDialog extends StatelessWidget {
  const TermsDialog({
    required this.onAccept,
    required this.onDecline,
    this.policiesArePlaceholders = LegalConstants.policiesArePlaceholders,
    this.privacyPolicyUrl = LegalConstants.privacyPolicyUrl,
    this.termsOfServiceUrl = LegalConstants.termsOfServiceUrl,
    super.key,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// Injected rather than read straight from [LegalConstants] so both renderings --
  /// the development warning and the real links -- stay reachable from a test.
  final bool policiesArePlaceholders;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;

  /// Shows the dialog and resolves to the user's answer. `false` means declined.
  static Future<bool> show(BuildContext context) async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => TermsDialog(
        onAccept: () => Navigator.of(context).pop(true),
        onDecline: () => Navigator.of(context).pop(false),
      ),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PopScope<Object?>(
      // The system back gesture would otherwise dismiss this as neither answer.
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: const Text('Before you start'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _policyLinks(context, theme),
                SizedBox(height: 16.h),
                Text(
                  'Using Duplika means agreeing to the terms above. This is what the app '
                  'keeps, and why:',
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 16.h),
                _Section(
                  title: 'Installed applications',
                  body: 'Duplika reads the list of apps installed on this device so it '
                      'can show you which ones can be cloned. The list is read on the '
                      'device, is not uploaded anywhere, and is not shared with anyone.',
                ),
                _Section(
                  title: 'Crash logs',
                  body: 'When something fails, Duplika records the error, when it '
                      'happened and basic device information. Package names, profile ids '
                      'and engine status are logged; the contents of your cloned apps, '
                      'their credentials and their tokens are never logged.',
                ),
                _Section(
                  title: 'What is not collected',
                  body: 'No account, no contacts, no messages, and nothing from inside a '
                      'clone. Clones write to their own private storage, which Duplika '
                      'does not read.',
                ),
              ],
            ),
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        actions: <Widget>[
          TextButton(onPressed: onDecline, child: const Text('Decline')),
          FilledButton(onPressed: onAccept, child: const Text('Accept')),
        ],
      ),
    );
  }

  Widget _policyLinks(BuildContext context, ThemeData theme) {
    final TextStyle? body = theme.textTheme.bodyMedium;
    final TextStyle link = (body ?? const TextStyle()).copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    if (policiesArePlaceholders) {
      // Presenting a dead example.com link as "our Privacy Policy" would be a lie in the
      // one dialog that must not contain any. Say what it is instead.
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          'Development build: the Privacy Policy and Terms of Service are not published '
          'yet, so there is nothing to link to. Do not ship this screen in this state.',
          style: body?.copyWith(color: theme.colorScheme.onErrorContainer),
        ),
      );
    }

    return Text.rich(
      TextSpan(
        style: body,
        children: <InlineSpan>[
          const TextSpan(text: 'Read our '),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _open(privacyPolicyUrl),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Terms of Service',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _open(termsOfServiceUrl),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    const AppLogger logger = AppLogger('TermsDialog');
    try {
      final bool opened =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened) {
        logger.error('No browser could open $url');
      }
    } on Object catch (error, stackTrace) {
      logger.error('Could not open $url', error, stackTrace);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleSmall),
          SizedBox(height: 4.h),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
