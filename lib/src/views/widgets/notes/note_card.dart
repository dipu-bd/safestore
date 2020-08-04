import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/views/screens/label_select.dart';
import 'package:safestore/src/views/screens/note_edit.dart';

import 'file:///C:/Users/Dipu/Projects/safestore/lib/src/views/widgets/notes/note_utils.dart';

class NoteCard extends StatelessWidget {
  final SimpleNote note;

  NoteCard(this.note, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
      margin: EdgeInsets.all(3),
      child: InkWell(
        onTap: () {
          if (note.isArchived) return;
          NoteEditDialog.show(context, note);
        },
        child: Stack(
          children: <Widget>[
            Padding(
              child: buildTile(),
              padding: EdgeInsets.only(right: 20),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: buildNoteDropDown(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTile() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildTitle(),
          SizedBox(height: note.body.isNotEmpty ? 5 : 0),
          buildBody(),
        ],
      ),
    );
  }

  Widget buildTitle() {
    return Container(
      child: Text(
        note.title,
        style: GoogleFonts.delius(
          fontSize: 20,
          color: Colors.amber,
        ),
      ),
    );
  }

  Widget buildBody() {
    if (note.body.isEmpty) {
      return Container();
    }
    return Text(
      note.body,
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.delius(
        fontSize: 14,
      ),
    );
  }

  Widget buildNoteDropDown(BuildContext context) {
    var menus = <PopupMenuEntry<int>>[
      PopupMenuItem(
        value: 1,
        child: Text('Edit labels'),
      ),
    ];
    if (!note.isArchived) {
      menus.addAll([
        PopupMenuItem(
          value: 2,
          child: Text('Archive note'),
        ),
      ]);
    } else {
      menus.addAll([
        PopupMenuItem(
          value: 3,
          child: Text('Restore note'),
        ),
        PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 4,
          child: Text('Delete forever'),
        ),
      ]);
    }

    return PopupMenuButton<int>(
      color: Color(0xff3d3c3d),
      icon: Icon(Icons.more_vert),
      itemBuilder: (context) => menus,
      offset: Offset(0, 40),
      onSelected: (value) {
        switch (value) {
          case 1:
            return handleEditLabels(context);
          case 2:
            return StoreBloc.of(context).state.storage.delete(note);
          case 3:
            return StoreBloc.of(context).state.storage.restore(note);
          case 4:
            return handleNoteDelete(context, note);
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
