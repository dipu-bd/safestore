import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/blocs/store_bloc.dart';

class PasswordScreen extends StatelessWidget {
  final passwordFocus = FocusNode();
  final textController = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Access Bin',
            style: GoogleFonts.anticSlab(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => handleLogout(context),
          ),
        ),
        body: BlocBuilder<StoreBloc, StoreState>(
          builder: (context, state) {
            if (state.loading || state.passwordError != null) {
              return Center(child: CircularProgressIndicator());
            }
            return WillPopScope(
              child: buildPasswordForm(context, state),
              onWillPop: () async {
                if (state.isPasswordReady) {
                  StoreBloc.of(context).clear();
                  return false;
                }
                return true;
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildPasswordForm(BuildContext context, StoreState state) {
    final auth = AuthBloc.of(context).state;
    if (!auth.isLoggedIn) return Container();
    return ListView(
      padding: EdgeInsets.all(20),
      children: <Widget>[
        SizedBox(height: kToolbarHeight),
        Container(
          alignment: Alignment.center,
          child: CircleAvatar(
            radius: 64,
            backgroundImage: CachedNetworkImageProvider(auth.picture),
          ),
        ),
        SizedBox(height: 10),
        Text(
          auth.username,
          style: GoogleFonts.anticSlab(
            fontSize: 28,
            color: Colors.amber,
          ),
          textAlign: TextAlign.center,
        ),
        Divider(height: 40),
        buildPasswordInput(context, state),
        Divider(height: 40),
        RaisedButton(
          color: Colors.blueGrey[700],
          child:
              Text(state.isPasswordReady ? 'Confirm and Continue' : 'Continue'),
          onPressed: () => handleSubmit(context),
        ),
        SizedBox(height: kToolbarHeight),
      ],
    );
  }

  Widget buildPasswordInput(BuildContext context, StoreState state) {
    return TextField(
      obscureText: true,
      focusNode: passwordFocus,
      controller: textController,
      maxLines: 1,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[900],
        errorText: (state.isPasswordReady && !state.isBinReady)
            ? 'Creating new bin'
            : null,
        labelText: !state.isPasswordReady
            ? 'Enter your bin key'
            : 'Confirm your bin key',
        counterText: 'Never share this with anyone',
      ),
      onSubmitted: (_) => handleSubmit(context),
    );
  }

  void handleSubmit(BuildContext context) {
    passwordFocus.unfocus();
    final state = StoreBloc.of(context).state;
    if (state.passwordHash == null) {
      StoreBloc.of(context).openBin(textController.text);
    } else {
      StoreBloc.of(context).createBin(textController.text);
    }
  }

  void handleLogout(BuildContext context) {
    passwordFocus.unfocus();
    StoreBloc.of(context).clear();
    AuthBloc.of(context).logout();
  }
}
