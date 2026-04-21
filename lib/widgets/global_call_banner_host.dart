import 'package:flutter/widgets.dart';

/// Wrapper for app-level call banner overlays.
///
/// Kept as a pass-through container for now so app builder references remain
/// stable even when the call banner feature is disabled or not yet wired.
class GlobalCallBannerHost extends StatelessWidget {
  const GlobalCallBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
