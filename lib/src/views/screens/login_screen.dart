import 'package:flutter/material.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AuthBloc.of(context).state;
    return SafeArea(
      child: Scaffold(
        body: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(15),
          child: state.loading
              ? buildLoading()
              : state.loginError != null && state.loginError.isNotEmpty
                  ? buildError(context)
                  : buildContent(),
        ),
      ),
    );
  }

  Widget buildLoading() {
    return CircularProgressIndicator();
  }

  Widget buildError(BuildContext context) {
    final state = AuthBloc.of(context).state;
    return AlertDialog(
      title: Text('Login Error'),
      content: Text(state.loginError ?? 'Something went wrong!'),
      actions: <Widget>[
        FlatButton(
          child: Text('Close'),
          onPressed: () => AuthBloc.of(context).logout(),
        )
      ],
    );
  }

  Widget buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircleAvatar(
          radius: 64,
          backgroundColor: Color(0xffc5363c),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Safestore',
          style: TextStyle(
            fontSize: 28,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'One place to store all your secrets',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 50),
        Builder(builder: buildLoginButton),
      ],
    );
  }

  Widget buildLoginButton(BuildContext context) {
    return RaisedButton(
      onPressed: () => AuthBloc.of(context).login(),
      child: Container(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Icon(Icons.fingerprint),
            SizedBox(width: 10),
            Text('Enter'),
          ],
        ),
        height: 42,
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width / 2,
      ),
    );
  }
}
