import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/simple_note.dart';

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
        floatingActionButton: buildFAB(context),
        body: buildForm(context),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        note.updatedAt != note.createdAt ? 'Edit Note' : 'New Note',
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

  Widget buildFAB(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.save),
      onPressed: () => handleSubmit(context),
    );
  }

  Widget buildForm(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildTitleField(context),
          Expanded(child: buildBodyField(context)),
        ],
      ),
    );
  }

  Widget buildTitleField(BuildContext context) {
    return TextField(
      focusNode: titleFocus,
      controller: titleController,
      style: GoogleFonts.delius(
        fontSize: 24,
        color: Colors.amber,
      ),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        hintText: 'Title',
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(15).copyWith(bottom: 5),
      ),
      onSubmitted: (_) => bodyFocus.requestFocus(),
    );
  }

  Widget buildBodyField(BuildContext context) {
    return TextField(
      maxLines: null,
      expands: true,
      focusNode: bodyFocus,
      controller: bodyController,
      textAlignVertical: TextAlignVertical.top,
      style: GoogleFonts.delius(fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        hintText: 'Your note here',
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(15).copyWith(top: 5),
      ),
    );
  }

  void handleSubmit(BuildContext context) async {
    // validity check
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (title.isEmpty) {
      return showDialog(
        context: context,
        child: AlertDialog(
          title: Text('Invalid Note'),
          content: Text('Note title can not be empty'),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }

    // save and close
    final state = StoreBloc.of(context).state;
    note.title = title;
    note.body = body;
    state.storage.save(note);
    Navigator.of(context).pop();
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
      final state = StoreBloc.of(context).state;
      state.storage.delete(note);
      Navigator.of(context).pop();
    }
  }
}
