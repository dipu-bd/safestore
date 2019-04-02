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
      backgroundColor: Colors.grey[200],
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
          image: DecorationImage(
            image: AssetImage('./assets/metal-back.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
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
    if (requireSignup) {
      if (password != repeatedPassword) {
        print('$password != $repeatedPassword');
        showPasswordMismatch();
        return;
      }
    }
    if (requireSignup) {
      await UserBloc.of(context).signup(password);
    } else {
      final res = await UserBloc.of(context).login(password);
      requireSignup = !res;
    }
    if (mounted) setState(() {});
  }

  void showPasswordMismatch() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Password Error'),
          content: const Text('The passwords you entered does not match'),
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
