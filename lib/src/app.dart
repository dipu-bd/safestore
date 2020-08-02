import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/views/screens/home_screen.dart';
import 'package:safestore/src/views/screens/login_screen.dart';
import 'package:safestore/src/views/screens/password_screen.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(),
        ),
        BlocProvider<StoreBloc>(
          create: (_) => StoreBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Safestore',
        theme: ThemeData.dark().copyWith(
          backgroundColor: Colors.grey[900],
          primaryColor: Colors.blueGrey,
          accentColor: Colors.amber,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (_, state) {
            if (!state.userFound) {
              return LoginScreen();
            }
            return BlocBuilder<StoreBloc, StoreState>(
              builder: (_, state) {
                if (!state.binFound) {
                  return PasswordScreen();
                }
                return HomeScreen();
              },
            );
          },
        ),
      ),
    );
  }
}
