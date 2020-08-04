import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/views/screens/label_select.dart';
import 'package:safestore/src/views/widgets/notes/note_edit_form.dart';
import 'package:safestore/src/views/widgets/notes/note_utils.dart';

class NoteEditDialog extends StatelessWidget {
  static Future<void> show(BuildContext context, SimpleNote note) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        maintainState: true,
        builder: (_) => NoteEditDialog(note),
      ),
    );
  }

  final SimpleNote note;
  final editing = SimpleNote();

  NoteEditDialog(this.note) {
    editing.copyFrom(note);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: buildAppBar(context),
        floatingActionButton: buildFAB(context),
        body: NoteEditForm(editing),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        note.isNew() ? 'New Note' : 'Edit Note',
        style: GoogleFonts.anticSlab(
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: <Widget>[
        buildDropDown(context),
      ],
    );
  }

  Widget buildFAB(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.save),
      onPressed: () {
        handleSubmit(context, editing);
        Navigator.of(context).pop();
      },
    );
  }

  Widget buildDropDown(BuildContext context) {
    final state = StoreBloc.of(context).state;
    if (!state.storage.hasItem(editing.id)) {
      return Container();
    }

    return PopupMenuButton<int>(
      color: Color(0xff3d3c3d),
      icon: Icon(Icons.more_vert),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: Text('Edit labels'),
        ),
        PopupMenuItem(
          value: 2,
          child: Text('Archive note'),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 1:
            return handleEditLabels(context);
          case 2:
            return state.storage.delete(editing);
        }
      },
    );
  }

  void handleEditLabels(BuildContext context) async {
    final save = await LabelSelectScreen.show(context, note.labels);
    if (save is bool && save) {
      StoreBloc.of(context).state.storage.save(note);
    }
  }
}
