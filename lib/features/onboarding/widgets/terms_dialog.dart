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
class TermsDialog extends StatefulWidget {
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

  /// The share of the screen the scrolling disclosure may occupy.
  ///
  /// Tall on purpose. A short box that happens to fit three lines invites a reflexive
  /// Accept; a panel that visibly holds more text says there is more text.
  static const double contentHeightFraction = 0.58;

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
  State<TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<TermsDialog> {
  final ScrollController _scroll = ScrollController();

  /// Whether disclosure text remains below the fold.
  bool _moreBelow = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncScrollEdge);
    // The first frame is what decides whether the text overflows at all, and the
    // controller has no position until then.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollEdge());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _syncScrollEdge() {
    if (!mounted || !_scroll.hasClients) {
      return;
    }
    // A pixel of slack: a fully scrolled view can report a fractional remainder.
    final bool moreBelow = _scroll.position.extentAfter > 1;
    if (moreBelow != _moreBelow) {
      setState(() => _moreBelow = moreBelow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double maxContentHeight =
        MediaQuery.sizeOf(context).height * TermsDialog.contentHeightFraction;

    return PopScope<Object?>(
      // The system back gesture would otherwise dismiss this as neither answer.
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
        title: const Text('Tips'),
        contentPadding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxContentHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _policyLinks(theme),
                        SizedBox(height: 20.h),
                        Text(
                          'Using Duplika means the app reads a specific set of data '
                          'from this device:',
                          style: theme.textTheme.bodyMedium,
                        ),
                        SizedBox(height: 20.h),
                        const _Section(
                          title: 'Installed applications',
                          body: 'Duplika reads the list of apps installed on this device '
                              'so it can show you which ones can be cloned. The list is '
                              'read on the device, is not uploaded anywhere, and is not '
                              'shared with anyone.',
                        ),
                        const _Section(
                          title: 'Crash logs',
                          body: 'When something fails, Duplika records the error, when it '
                              'happened and basic device information. Package names, '
                              'profile ids and engine status are logged; the contents of '
                              'your cloned apps, their credentials and their tokens are '
                              'never logged.',
                        ),
                        const _Section(
                          title: 'What is not collected',
                          body: 'No account, no contacts, no messages, and nothing from '
                              'inside a clone. Clones write to their own private storage, '
                              'which Duplika does not read.',
                        ),
                      ],
                    ),
                  ),
                ),
                // A scroll affordance, not decoration: the rule is only there while text
                // remains below the fold, so the buttons never look like the end of a
                // document the user has not reached the end of.
                AnimatedOpacity(
                  opacity: _moreBelow ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Divider(
                    height: 24.h,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        actions: <Widget>[
          // Both answers are text buttons of the same weight. Giving Accept the heavier
          // affordance would be steering the one decision the user is here to make.
          TextButton(
            onPressed: widget.onDecline,
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: widget.onAccept,
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Widget _policyLinks(ThemeData theme) {
    final TextStyle? body = theme.textTheme.bodyMedium;
    final TextStyle link = (body ?? const TextStyle()).copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    if (widget.policiesArePlaceholders) {
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
              ..onTap = () => _open(widget.privacyPolicyUrl),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Terms of Service',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _open(widget.termsOfServiceUrl),
          ),
          const TextSpan(text: '. Tap Accept to agree to our policies and terms.'),
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
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
