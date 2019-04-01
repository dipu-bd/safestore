import 'package:flutter/material.dart';
import '../commons/screen.dart';

class HomePage extends Screen {
  @override
  bool matchRoute(String route) => route == '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBody(),
      appBar: AppBar(
        title: Text('SafeStore'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.lock),
            color: Colors.red,
            onPressed: () {
              // TODO: logout from session
            },
          )
        ],
      ),
    );
  }

  Widget buildBody() {
    return Container();
  }
}
