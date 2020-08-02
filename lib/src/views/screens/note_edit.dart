import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/notes_bloc.dart';
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
      child: Scaffold(
        appBar: buildAppBar(),
        body: buildForm(context),
        floatingActionButton: buildFAB(),
      ),
    );
  }

  Widget buildAppBar() {
    return AppBar(
      title: Text(
        'New Note',
        style: GoogleFonts.baloo(),
      ),
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
}
