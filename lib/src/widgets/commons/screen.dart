import 'package:flutter/material.dart';
import '../login/ensure-login.dart';
import 'fade-in-route.dart';

abstract class Screen {
  bool matchRoute(String route);
  Widget build(BuildContext context, RouteSettings route);

  Route buildRoute(RouteSettings route) {
    if (!matchRoute(route.name)) {
      return null;
    }
    return FadeInRoute(
      settings: route,
      maintainState: true,
      builder: (context) {
        return EnsureLogin(
          child: build(context, route),
        );
      },
    );
  }
}
