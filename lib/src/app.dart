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
          create: (context) => AuthBloc(),
        ),
        BlocProvider<StoreBloc>(
          create: (context) => StoreBloc(context),
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
      builder: (context, state) => withAnimatedSwitcher(
        () {
          if (state.loginError != null) {
            return buildError(
              state.loginError,
              title: 'Login Error',
              onClose: (context) => AuthBloc.of(context).logout(),
            );
          }
          if (!state.isLoggedIn) {
            return LoginScreen();
          }
          return buildHomePage();
        },
      ),
    );
  }

  Widget buildHomePage() {
    return BlocBuilder<StoreBloc, StoreState>(
      builder: (context, state) => withAnimatedSwitcher(
        () {
          if (state.passwordError != null) {
            return buildError(
              state.passwordError,
              title: 'Password Error',
              onClose: (context) => StoreBloc.of(context).clear(),
            );
          }
          if (state.syncError != null) {
            return buildError(
              state.syncError,
              title: 'Sync Error',
              onClose: (context) => StoreBloc.of(context).sync(),
            );
          }
          if (!state.isBinReady) {
            return PasswordScreen();
          }
          return NoteListScreen();
        },
      ),
    );
  }

  Widget withAnimatedSwitcher(Widget Function() builder, {Duration duration}) {
    return AnimatedSwitcher(
      child: builder(),
      duration: duration ?? Duration(milliseconds: 500),
    );
  }

  Widget buildError(error, {title, Function(BuildContext) onClose}) {
    return Builder(
      builder: (context) => Scaffold(
        body: AlertDialog(
          title: Text('${title ?? 'Error'}'),
          content: Text('$error'),
          actions: <Widget>[
            FlatButton(
              child: Text('Close'),
              onPressed: () => onClose(context),
            ),
          ],
        ),
      ),
    );
  }
}
