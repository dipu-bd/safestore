import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/views/screens/about_screen.dart';

class MainDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 30),
          buildUser(context),
          Divider(height: 1),
          SizedBox(height: 10),
          Expanded(child: buildMenu(context)),
          SizedBox(height: 10),
          Divider(height: 1),
          SizedBox(height: 10),
          buildLogoutButton(context),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget buildUser(BuildContext context) {
    final auth = AuthBloc.of(context).state;
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: CachedNetworkImageProvider(auth.picture),
      ),
      title: Text(
        auth.username,
        style: GoogleFonts.baloo(fontSize: 16),
      ),
      subtitle: Text(
        auth.email,
        style: GoogleFonts.delius(
          fontSize: 14,
          color: Colors.amber,
        ),
      ),
    );
  }

  Widget buildLogoutButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      child: RaisedButton(
        color: Colors.amber,
        textColor: Colors.black,
        onPressed: () => handleLogout(context),
        child: Container(
          alignment: Alignment.center,
          child: Text('Logout'),
        ),
      ),
    );
  }

  Widget buildMenu(BuildContext context) {
    final state = StoreBloc.of(context).state;
    return ListView(
      padding: EdgeInsets.all(10),
      children: <Widget>[
        buildLabel(context, SimpleNote.LABEL_DEFAULT),
        buildLabel(context, SimpleNote.LABEL_ARCHIVE),
        state.labels.isNotEmpty ? Divider() : Container(),
        ...state.labels.map((label) => buildLabel(context, label)),
        Divider(),
        ListTile(
          leading: Icon(Icons.info),
          title: Text('System Info'),
          onTap: () {
            Navigator.of(context).pop();
            AboutScreen.show(context);
          },
        ),
      ],
    );
  }

  Widget buildLabel(BuildContext context, label) {
    final state = StoreBloc.of(context).state;
    bool selected = label == state.currentLabel;
    var icon = Icons.label_outline;
    if (label == SimpleNote.LABEL_DEFAULT) {
      icon = Icons.lightbulb_outline;
    } else if (label == SimpleNote.LABEL_ARCHIVE) {
      icon = Icons.archive;
    } else if (selected) {
      icon = Icons.label;
    }
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Colors.amber : null,
      ),
      title: Text(
        label ?? 'All',
        style: TextStyle(
          color: selected ? Colors.amber : null,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        state.currentLabel = label;
        StoreBloc.of(context).notify();
      },
    );
  }

  void handleLogout(BuildContext context) {
    StoreBloc.of(context).clear();
    AuthBloc.of(context).logout();
  }
}
