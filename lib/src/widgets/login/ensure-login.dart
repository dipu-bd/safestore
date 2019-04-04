import 'package:flutter/material.dart';
import 'package:safestore/src/blocs/user_bloc.dart';
import 'password-box.dart';

class EnsureLogin extends StatefulWidget {
  final Widget child;

  EnsureLogin({
    Key key,
    @required this.child,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EnsureLoginState();
}

class _EnsureLoginState extends State<EnsureLogin> {
  bool requireSignup = false;
  String password, repeatedPassword;

  void reset() {
    password = null;
    repeatedPassword = null;
    requireSignup = false;
  }

  @override
  Widget build(BuildContext context) {
    final userBloc = UserBloc.of(context);
    return StreamBuilder(
      stream: userBloc.user,
      builder: (_, snapshot) {
        if (snapshot.data == null) {
          return buildPasswordLogin();
        } else {
          return widget.child;
        }
      },
    );
  }

  Widget buildProgress() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget buildPasswordLogin() {
    final children = List<Widget>();
    children.add(buildEnterPassword());
    if (requireSignup) {
      children.add(SizedBox(height: 15));
      children.add(buildVerifyPassword());
    }
    return Scaffold(
      body: Container(
        child: Column(
          children: children,
          mainAxisSize: MainAxisSize.min,
        ),
        padding: EdgeInsets.all(15.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey[50],
              Colors.teal[200],
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget buildEnterPassword() {
    return PasswordBox(
      autofocus: !requireSignup,
      hintText: 'Enter Password',
      onChange: (v) => password = v,
      onSubmit: (_) => checkPassword(),
    );
  }

  Widget buildVerifyPassword() {
    return PasswordBox(
      autofocus: requireSignup,
      hintText: 'Verify Password',
      onChange: (v) => repeatedPassword = v,
      onSubmit: (_) => checkPassword(),
    );
  }

  void checkPassword() async {
    if (password == null || password == '') {
      return showAlertDialog(
        title: 'Input Error',
        message: 'Password should not be empty',
      );
    }
    if (requireSignup) {
      if (password != repeatedPassword) {
        return showAlertDialog(
          title: 'Input Error',
          message: 'The passwords you entered does not match',
        );
      }
    }
    try {
      if (requireSignup) {
        await UserBloc.of(context).signup(password);
      } else {
        await UserBloc.of(context).signin(password);
      }
      this.reset();
    } catch (err) {
      requireSignup = true;
      showAlertDialog(
        title: 'Error',
        message: err.toString(),
      );
    } finally {
      if (mounted) setState(() {});
    }
  }

  void showAlertDialog({String title, String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              child: Text('Retry'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
