import 'package:flutter/material.dart';
import 'package:safestore/src/blocs/user_bloc.dart';
import '../commons/screen.dart';

class HomePage extends Screen {
  @override
  bool matchRoute(String route) => route == '/';

  @override
  Widget build(BuildContext context, RouteSettings route) {
    return Scaffold(
      body: buildBody(),
      appBar: AppBar(
        title: Text('Safe Store'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.lock),
            onPressed: () {
              UserBloc.of(context).signout();
            },
          )
        ],
      ),
    );
  }

  Widget buildBody() {
    return Center(
      child: Text('Under construction'),
    );
  }
}
