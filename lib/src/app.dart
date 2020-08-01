import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/views/screens/home_screen.dart';
import 'package:safestore/src/views/screens/login_screen.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(),
      child: MaterialApp(
        title: 'Safestore',
        theme: ThemeData.dark(),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (_, state) {
            if (state.email == null) {
              return LoginScreen();
            } else {
              return HomeScreen();
            }
          },
        ),
      ),
    );
  }
}
