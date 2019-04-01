import 'package:flutter/material.dart';
import 'fade-in-route.dart';

abstract class Screen {
  bool matchRoute(String route);
  Widget build(BuildContext context);

  Route buildRoute(RouteSettings settings) {
    if (!matchRoute(settings.name)) {
      return null;
    }
    return FadeInRoute(
      settings: settings,
      maintainState: true,
      builder: build,
    );
  }
}
