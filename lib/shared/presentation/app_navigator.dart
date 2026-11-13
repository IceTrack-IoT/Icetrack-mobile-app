import 'package:flutter/material.dart';

/// Root navigator, used to leave any screen when the session expires and to open a tapped push.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Root messenger, used to show a push that arrives while the app is open.
final GlobalKey<ScaffoldMessengerState> appMessengerKey = GlobalKey<ScaffoldMessengerState>();
