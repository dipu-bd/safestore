import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/views/screens/label_select.dart';

void handleSubmit(BuildContext context, SimpleNote note) async {
  // validity check
  if (note.title.isEmpty) {
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
  SimpleNote original = state.storage.find(note.id);
  if (original == null ||
      note.title != original.title ||
      note.body != original.body) {
    state.storage.save(note);
  }
}

void handleNoteDelete(BuildContext context, SimpleNote note) async {
  final confirm = await showDialog(
    context: context,
    child: AlertDialog(
      title: Text('Delete Note'),
      content: Text('Are you sure to delete this note forever?'),
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
    StoreBloc.of(context).state.storage.delete(note);
  }
}

void handleEditLabels(BuildContext context, SimpleNote note) async {
  bool changed = await LabelSelectScreen.show(context, note.labels);

  final state = StoreBloc.of(context).state;
  SimpleNote original = state.storage.find(note.id);
  if (original != null &&
      listEquals(original.labels.toList(), note.labels.toList())) {
    changed = false;
  }

  if (changed ?? false) {
    final state = StoreBloc.of(context).state;
    state.storage.save(note);
  }
}
