import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/utils/to_string.dart';

class MainDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 30),
          buildUser(context),
          SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(10),
                child: buildStat(context),
              ),
            ),
          ),
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
    return Material(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            CircleAvatar(
              radius: 54,
              backgroundImage: CachedNetworkImageProvider(auth.picture),
            ),
            SizedBox(height: 10),
            Text(
              auth.username,
              style: GoogleFonts.baloo(fontSize: 18),
            ),
            Text(
              auth.email,
              style: GoogleFonts.delius(
                fontSize: 15,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextValue(String title, String value) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: '$title: ',
          style: TextStyle(color: Colors.grey[100]),
        ),
        TextSpan(
          text: value,
          style: TextStyle(color: Colors.lime[100]),
        ),
      ]),
      style: GoogleFonts.firaMono(fontSize: 14),
      textAlign: TextAlign.start,
    );
  }

  Widget buildStat(BuildContext context) {
    final store = StoreBloc.of(context).state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        buildTextValue('Bin ID', store.binName),
        SizedBox(height: 8),
        buildTextValue('Bin checksum (MD5)', store.lastDriveMd5),
        SizedBox(height: 8),
        buildTextValue('Data size', formatFileSize(store.driveFileSize)),
        SizedBox(height: 8),
        buildTextValue('Data checksum (MD5)', store.lastDataMd5),
        SizedBox(height: 8),
        buildTextValue('Total items', store.storage.totalItems.toString()),
        SizedBox(height: 8),
        buildTextValue('Last Synced', store.storage.lastSyncTime.toString()),
        SizedBox(height: 8),
        Divider(),
        buildTextValue('Password Hash', ''),
        SizedBox(height: 8),
        QrImage(
          data: String.fromCharCodes(store.passwordHash),
          backgroundColor: Colors.white,
          size: 160,
        ),
      ],
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

  void handleLogout(BuildContext context) {
    StoreBloc.of(context).clear();
    AuthBloc.of(context).logout();
  }
}
