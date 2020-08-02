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
  void onLogout(BuildContext context) {
    NoteBloc.of(context).clear();
    StoreBloc.of(context).clear();
    AuthBloc.of(context).logout();
  }

  @override
  Widget build(BuildContext context) {
    final state = NoteBloc.of(context).state;
    final store = StoreBloc.of(context).state;
    if (!state.loading && state.notes == null) {
      NoteBloc.of(context).loadNotes();
    }
    return SafeArea(
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
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              height: MediaQuery.of(context).size.height,
              child: buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
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
              onPressed: () => onLogout(context),
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
          return buildError(state.loadError);
        }
        if (state.loading) {
          return CircularProgressIndicator();
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
            onPressed: () => onLogout(context),
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
      children: state.notes.map((note) {
        return Card(
          child: ListTile(
            title: Text(
              note.title,
              style: GoogleFonts.delius(fontSize: 20, color: Colors.amber),
            ),
            subtitle: Text(
              note.body.length > 1500
                  ? note.body.substring(0, 1500) + '...'
                  : note.body,
              style: GoogleFonts.delius(fontSize: 14),
            ),
            onTap: () => NoteEditDialog.show(context, note),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => handleNoteDelete(context, note),
            ),
          ),
        );
      }).toList(),
    );
  }

  void handleNoteDelete(BuildContext context, Note note) async {
    final confirm = await showDialog(
      context: context,
      child: AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure to delete this note?'),
        actions: <Widget>[
          FlatButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
          FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'No',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
    if (confirm) {
      await NoteBloc.of(context).deleteNote(note);
    }
  }
}
