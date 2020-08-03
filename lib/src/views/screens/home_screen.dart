import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/views/screens/note_edit.dart';
import 'package:safestore/src/views/widgets/main_drawer.dart';

class HomeScreen extends StatelessWidget {
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
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(5),
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

  Widget buildFAB(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () => NoteEditDialog.show(context, SimpleNote()),
    );
  }

  Widget buildContent(BuildContext context) {
    final state = StoreBloc.of(context).state;
    final notes = state.storage.findAll<SimpleNote>();
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
}
