import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AuthBloc.of(context).state;
    return SafeArea(
      top: false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(15),
            height: MediaQuery.of(context).size.height - 24,
            child: state.loading || state.loginError != null
                ? CircularProgressIndicator()
                : buildLoginForm(),
          ),
        ),
      ),
    );
  }

  Widget buildLoginForm() {
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
          style: GoogleFonts.baloo(
            fontSize: 28,
            color: Colors.amber,
          ),
        ),
        Text(
          'One place to store all your secrets',
          style: GoogleFonts.anticSlab(
            fontSize: 16,
          ),
        ),
        SizedBox(height: 100),
        Builder(builder: buildLoginButton),
      ],
    );
  }

  Widget buildLoginButton(BuildContext context) {
    return RaisedButton(
      color: Colors.blueGrey,
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
