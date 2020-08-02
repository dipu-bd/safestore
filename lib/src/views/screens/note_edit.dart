import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/notes_bloc.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/note.dart';

class NoteEditDialog extends StatelessWidget {
  static Future<void> show(BuildContext context, Note note) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        maintainState: true,
        builder: (_) => NoteEditDialog(note),
      ),
    );
  }

  final Note note;
  final titleFocus = FocusNode();
  final bodyFocus = FocusNode();
  final TextEditingController titleController;
  final TextEditingController bodyController;

  NoteEditDialog(this.note, {Key key})
      : titleController = TextEditingController(text: note.title),
        bodyController = TextEditingController(text: note.body),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: buildAppBar(context),
        body: buildForm(context),
        floatingActionButton: buildFAB(),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        note.updateTime != note.createTime ? 'Edit Note' : 'New Note',
        style: GoogleFonts.baloo(),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => handleNoteDelete(context),
        ),
      ],
    );
  }

  Widget buildFAB() {
    return BlocBuilder<NoteBloc, NoteState>(
      builder: (context, state) {
        return FloatingActionButton(
          child: state.saving ? CircularProgressIndicator() : Icon(Icons.save),
          onPressed: () async {
            if (state.saving) return;
            note.title = titleController.text;
            note.body = bodyController.text;
            await NoteBloc.of(context).saveNote(note);
            StoreBloc.of(context).sync(); // do a sync
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget buildForm(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            focusNode: titleFocus,
            controller: titleController,
            style: GoogleFonts.delius(fontSize: 20, color: Colors.amber),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900],
              hintText: 'Title',
              border: InputBorder.none,
            ),
            onSubmitted: (_) => bodyFocus.requestFocus(),
          ),
          SizedBox(height: 5),
          Expanded(
            child: TextField(
              maxLines: null,
              expands: true,
              focusNode: bodyFocus,
              controller: bodyController,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.delius(fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                hintText: 'Your note here',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void handleNoteDelete(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      child: AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure to delete this note?'),
        actions: <Widget>[
          FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          FlatButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
    if (confirm) {
      await NoteBloc.of(context).deleteNote(note);
      StoreBloc.of(context).sync(); // do a sync
      Navigator.of(context).pop();
    }
  }
}
