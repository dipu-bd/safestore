import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/blocs/storage_bloc.dart';

class PasswordScreen extends StatelessWidget {
  final passwordFocus = FocusNode();
  final textController = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    final state = StoreBloc.of(context).state;
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Access Bin',
            style: GoogleFonts.baloo(),
          ),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => handleLogout(context),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height - kToolbarHeight - 24,
            child: state.loading
                ? buildLoading(context)
                : state.passwordError != null && state.passwordError.isNotEmpty
                    ? buildError(context)
                    : buildPasswordForm(context),
          ),
        ),
      ),
    );
  }

  Widget buildLoading(BuildContext context) {
    return CircularProgressIndicator();
  }

  Widget buildError(BuildContext context) {
    final state = StoreBloc.of(context).state;
    return AlertDialog(
      title: Text('Password Error'),
      content: Text(state.passwordError ?? 'Something went wrong!'),
      actions: <Widget>[
        FlatButton(
          child: Text('Close'),
          onPressed: () => StoreBloc.of(context).clear(),
        )
      ],
    );
  }

  Widget buildPasswordForm(BuildContext context) {
    final auth = AuthBloc.of(context).state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircleAvatar(
          radius: 64,
          backgroundImage: CachedNetworkImageProvider(auth.picture),
        ),
        SizedBox(height: 10),
        Text(
          auth.username,
          style: GoogleFonts.anticSlab(
            fontSize: 28,
            color: Colors.amber,
          ),
        ),
        Divider(height: 40),
        TextField(
          obscureText: true,
          focusNode: passwordFocus,
          controller: textController,
          maxLines: 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            labelText: 'Enter your bin key',
            counterText: 'Never share this with anyone',
          ),
          onSubmitted: (_) => passwordFocus.unfocus(),
        ),
        Divider(height: 40),
        RaisedButton(
          color: Colors.blueGrey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Text('Enter'),
          ),
          onPressed: () => StoreBloc.of(context).openBin(textController.text),
        ),
      ],
    );
  }

  void handleLogout(BuildContext context) {
    StoreBloc.of(context).clear();
    AuthBloc.of(context).logout();
  }
}
