import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/views/screens/login_screen.dart';
import 'package:safestore/src/views/screens/note_list_screen.dart';
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
          scaffoldBackgroundColor: Color(0xff1d1d1f),
          cardColor: Color(0xff2f2c2f),
          primaryColor: Color(0xff2a2a2a),
          accentColor: Colors.amber,
          dividerColor: Color(0xff5f5f5f),
          primaryColorDark: Color(0xff3d3d3d),
        ),
        home: buildAuthPage(),
      ),
    );
  }

  Widget buildAuthPage() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (_, state) => withAnimatedSwitcher(
        () {
          if (!state.userFound) {
            return LoginScreen();
          }
          return buildHomePage();
        },
      ),
    );
  }

  Widget buildHomePage() {
    return BlocBuilder<StoreBloc, StoreState>(
      builder: (_, state) => withAnimatedSwitcher(
        () {
          if (!state.binFound) {
            return PasswordScreen();
          }
          return NoteListScreen();
        },
      ),
    );
  }

  Widget withAnimatedSwitcher(Widget Function() builder, {Duration duration}) {
    return AnimatedSwitcher(
      duration: duration ?? Duration(milliseconds: 500),
      child: builder(),
    );
  }
}
