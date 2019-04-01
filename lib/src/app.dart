import 'package:flutter/material.dart';
import 'package:safestore/src/blocs/user_bloc.dart';
import 'package:safestore/src/blocs/bloc_provider.dart';
import 'package:safestore/src/widgets/screens/home.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      bloc: UserBloc(),
      child: app(),
    );
  }

  Widget app() {
    return MaterialApp(
      title: 'Safe Store',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      onGenerateRoute: (settings) {
        return HomePage().buildRoute(settings) ?? buildUknownRoute(settings);
      },
    );
  }

  MaterialPageRoute buildUknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) {
        return Scaffold(
          body: Center(
            child: Text(
              '${settings.name}\nThis page is not available yet',
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.grey[600],
                fontSize: 20.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
