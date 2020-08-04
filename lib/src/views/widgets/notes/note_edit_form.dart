import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/models/simple_note.dart';

class NoteEditForm extends StatefulWidget {
  final SimpleNote note;

  NoteEditForm(this.note, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NoteEditFormState();
}

class _NoteEditFormState extends State<NoteEditForm> {
  final titleFocus = FocusNode();
  final bodyFocus = FocusNode();

  SimpleNote get note => widget.note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildTitleField(),
          Expanded(child: buildBodyField()),
        ],
      ),
    );
  }

  Widget buildTitleField() {
    return TextField(
      focusNode: titleFocus,
      controller: TextEditingController(text: note.title),
      onSubmitted: (_) => bodyFocus.requestFocus(),
      onChanged: (value) => note.title = value.trim(),
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
    );
  }

  Widget buildBodyField() {
    return TextField(
      focusNode: bodyFocus,
      onChanged: (value) => note.body = value.trim(),
      controller: TextEditingController(text: note.body),
      maxLines: null,
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
}
