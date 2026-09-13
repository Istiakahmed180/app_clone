import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';

/// The prominent data-and-permissions disclosure Play requires before the app reads the
/// installed-app inventory that `QUERY_ALL_PACKAGES` makes available.
///
/// This is a gate, not a banner: the user has to accept it before the clone picker — and
/// therefore before any installed-app data is read — is reachable. That is deliberate.
/// The old terms dialog carried this disclosure and was removed; nothing replaced it, so
/// the disclosure lived only inside a Privacy Policy the user was never shown. Play does
/// not accept that for `QUERY_ALL_PACKAGES`, and neither does the honesty rule this
/// project holds itself to.
///
/// It states three things, in the order they matter: what is read, what is read on the
/// user's behalf, and that every one of it is optional. It makes no privacy claim the app
/// cannot keep — there is no ads SDK, no analytics and no HTTP client to leak through.
class DataDisclosure extends StatelessWidget {
  const DataDisclosure({required this.onAccept, super.key});

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 16.h),
                children: <Widget>[
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.privacy_tip_outlined,
                      size: 30.r,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Before you start',
                    style: theme.textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${AppConstants.appTitle} runs a second copy of apps you choose. '
                    'Here is exactly what it reads and what it will ask you for.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 24.h),
                  _Section(
                    icon: Icons.apps_outlined,
                    title: 'Your installed apps',
                    body:
                        'To show the clone picker, ${AppConstants.appTitle} reads the '
                        'list of apps installed on this device — their names, icons and '
                        'versions. This list stays on your device. It is never uploaded, '
                        'sold or shared, and the app contains no ads, no analytics and '
                        'no tracker.',
                  ),
                  _Section(
                    icon: Icons.security_outlined,
                    title: 'Permissions on behalf of clones',
                    body:
                        'Cloned apps run inside ${AppConstants.appTitle}, so some Android '
                        'permissions apply to it on their behalf. You may be asked once '
                        'to exempt it from battery optimisation so cloned messengers '
                        'keep delivering. Only when you clone a file or media app, you '
                        'may need to grant All files access in Settings.',
                  ),
                  _Section(
                    icon: Icons.tune_outlined,
                    title: 'You stay in control',
                    body:
                        'Nothing is requested silently. You can refuse any of these '
                        'requests and still use the app, and you can change your mind in '
                        'Android Settings at any time.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 20.h),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAccept,
                  child: const Text('Agree and continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 22.r, color: theme.colorScheme.primary),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleSmall),
                SizedBox(height: 4.h),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
