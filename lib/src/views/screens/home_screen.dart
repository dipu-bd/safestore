import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/blocs/notes_bloc.dart';
import 'package:safestore/src/blocs/storage_bloc.dart';
import 'package:safestore/src/models/note.dart';
import 'package:safestore/src/views/screens/note_edit.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = NoteBloc.of(context).state;
    final store = StoreBloc.of(context).state;
    if (!state.loading && state.notes == null) {
      NoteBloc.of(context).loadNotes();
    }
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: buildAppBar(context),
        drawer: buildDrawer(context),
        floatingActionButton: buildFAB(context),
        body: RefreshIndicator(
          onRefresh: () async {
            if (state.loading || store.syncing) return;
            await StoreBloc.of(context).sync();
            await NoteBloc.of(context).loadNotes();
          },
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
              ),
              child: buildContent(),
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
          onPressed: () => StoreBloc.of(context).sync(),
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

  Widget buildContent() {
    return BlocBuilder<NoteBloc, NoteState>(
      builder: (context, state) {
        if (state.loadError != null) {
          return Center(
            child: buildError(state.loadError),
          );
        }
        if (state.loading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return buildNotes(context);
      },
    );
  }

  Widget buildError(String error) {
    return Builder(
      builder: (context) => AlertDialog(
        title: Text(
          'Load Error',
          style: GoogleFonts.openSans(color: Colors.amber),
        ),
        content: Text(
          error,
          style: GoogleFonts.firaMono(fontSize: 14),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: () => handleLogout(context),
            child: Text('Logout'),
          ),
          FlatButton(
            onPressed: () => NoteBloc.of(context).loadNotes(),
            child: Text('Retry', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget buildNotes(BuildContext context) {
    final state = NoteBloc.of(context).state;
    if (state.notes == null || state.notes.isEmpty) {
      return Container(
        child: Text('No notes found'),
      );
    }
    return Column(
      children: <Widget>[
        ...state.notes.map((note) {
          return Card(
            child: ListTile(
              title: Text(
                note.title,
                style: GoogleFonts.delius(fontSize: 20, color: Colors.amber),
              ),
              subtitle: Text(
                note.body.length > 500
                    ? note.body.substring(0, 500) + '...'
                    : note.body,
                style: GoogleFonts.delius(fontSize: 14),
              ),
              onTap: () => NoteEditDialog.show(context, note),
            ),
          );
        }),
      ],
    );
  }

  void handleLogout(BuildContext context) {
    NoteBloc.of(context).clear();
    StoreBloc.of(context).clear();
    AuthBloc.of(context).logout();
  }
}
