import 'package:flutter/widgets.dart';

/// Global navigator key used by widgets rendered above the Navigator
/// (such as CompletionOverlay) to push dialogs onto the app's routes.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();