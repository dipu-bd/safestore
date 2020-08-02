import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/note.dart';
import 'package:safestore/src/views/screens/note_edit.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: buildAppBar(context),
        drawer: buildDrawer(context),
        floatingActionButton: buildFAB(context),
        body: RefreshIndicator(
          onRefresh: () => handleRefresh(context),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
              ),
              child: buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    final store = StoreBloc.of(context).state;
    return AppBar(
      title: Text(
        'Notes',
        style: GoogleFonts.baloo(),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.sync),
          onPressed: () => handleRefresh(context),
        ),
      ],
      bottom: store.syncing
          ? PreferredSize(
              preferredSize: Size.fromHeight(5),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(),
              ),
            )
          : null,
    );
  }

  Drawer buildDrawer(BuildContext context) {
    final auth = AuthBloc.of(context).state;
    return Drawer(
      child: Column(
        children: <Widget>[
          Material(
            elevation: 3,
            child: Container(
              padding: EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: 64,
                    backgroundImage: CachedNetworkImageProvider(auth.picture),
                  ),
                  SizedBox(height: 10),
                  Text(auth.username)
                ],
              ),
            ),
          ),
          Expanded(child: Container()),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(15.0),
            child: RaisedButton(
              color: Colors.amber,
              textColor: Colors.black,
              onPressed: () => handleLogout(context),
              child: Container(
                alignment: Alignment.center,
                child: Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFAB(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () => NoteEditDialog.show(context, Note()),
    );
  }

  Widget buildContent(BuildContext context) {
    final state = StoreBloc.of(context).state;
    final notes = state.storage.finalAll();
    if (notes.isEmpty) {
      return Center(
        child: Text(
          'No notes found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Column(
      children: <Widget>[
        ...notes.map((note) {
          return Card(
            child: ListTile(
              title: Text(
                note.title,
                style: GoogleFonts.delius(fontSize: 20, color: Colors.amber),
              ),
              subtitle: note.body.isNotEmpty
                  ? Text(
                      note.body.length > 500
                          ? note.body.substring(0, 500) + '...'
                          : note.body,
                      style: GoogleFonts.delius(fontSize: 14),
                    )
                  : null,
              onTap: () => NoteEditDialog.show(context, note),
            ),
          );
        }),
      ],
    );
  }

  Future<void> handleRefresh(BuildContext context) async {
    StoreBloc.of(context).sync();
  }

  void handleLogout(BuildContext context) {
    StoreBloc.of(context).clear();
    AuthBloc.of(context).logout();
  }
}
