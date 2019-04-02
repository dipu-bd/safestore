import 'package:flutter/material.dart';
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
              // TODO: logout from session
              print('Not yet implemented');
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
