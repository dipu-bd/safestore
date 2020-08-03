import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/views/screens/note_edit.dart';
import 'package:safestore/src/views/widgets/main_drawer.dart';
import 'package:safestore/src/views/widgets/notes/note_card.dart';

class NoteListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: buildAppBar(context),
        drawer: MainDrawer(),
        floatingActionButton: buildFAB(context),
        body: RefreshIndicator(
          onRefresh: () => handleRefresh(context),
          child: buildContent(context),
        ),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    final store = StoreBloc.of(context).state;
    return AppBar(
      title: Text(
        '${store.currentLabel ?? 'All'} Notes',
        style: GoogleFonts.anticSlab(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
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

  Widget buildFAB(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () => NoteEditDialog.show(context, SimpleNote()),
    );
  }

  Widget buildContent(BuildContext context) {
    final state = StoreBloc.of(context).state;
    final label = state.currentLabel;
    final notes = state.storage.findAll<SimpleNote>((note) {
      if (label == 'Archived') return note.deleted;
      if (note.deleted) return false;
      if (label == null) return true;
      return (note.labels.contains(label));
    });

    if (notes.isEmpty) {
      return Center(
        child: Text(
          'No notes found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.all(5).copyWith(bottom: 100),
      children: <Widget>[
        ...notes.map((note) => NoteCard(note)),
      ],
    );
  }

  Future<void> handleRefresh(BuildContext context) async {
    StoreBloc.of(context).sync();
  }
}
