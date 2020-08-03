import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/views/screens/note_edit.dart';
import 'package:safestore/src/views/widgets/notes/group_chip.dart';

class NoteCard extends StatelessWidget {
  final SimpleNote note;

  NoteCard(this.note, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => NoteEditDialog.show(context, note),
        child: buildTile(),
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
          SizedBox(height: 5),
          buildTags(),
        ],
      ),
    );
  }

  Widget buildTitle() {
    return Text(
      note.title,
      style: GoogleFonts.delius(
        fontSize: 20,
        color: Colors.amber,
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

  Widget buildTags() {
    return Container(
      child: Wrap(
        children: <Widget>[
          ...note.groups.map((e) => GroupChip(e)),
        ],
      ),
    );
  }
}
