import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/utils/to_string.dart';
import 'package:safestore/src/views/widgets/main_drawer.dart';

class AboutScreen extends StatelessWidget {
  static Future show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: false,
        maintainState: true,
        builder: (_) => AboutScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        drawer: MainDrawer(),
        appBar: buildAppBar(context),
        body: buildContent(context),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    final store = StoreBloc.of(context).state;
    return AppBar(
      title: Text(
        'About',
        style: GoogleFonts.anticSlab(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      bottom: store.syncing
          ? PreferredSize(
              preferredSize: Size.fromHeight(5),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(),
              ),
            )
          : null,
    );
  }

  Widget buildContent(BuildContext context) {
    final store = StoreBloc.of(context).state;
    return ListView(
      padding: EdgeInsets.all(10),
      children: <Widget>[
        buildItem(title: 'Bin ID', value: store.binName),
        buildItem(title: 'Bin checksum (MD5)', value: store.lastDriveMd5),
        Divider(),
        buildItem(
            title: 'Data size', value: formatFileSize(store.driveFileSize)),
        buildItem(title: 'Data checksum (MD5)', value: store.lastDataMd5),
        buildItem(
            title: 'Total items', value: store.storage.totalItems.toString()),
        buildItem(
            title: 'Last Synced', value: store.storage.lastSyncTime.toString()),
        Divider(),
        buildItem(
          title: 'Password Hash',
          subtitle: Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(top: 10),
            child: QrImage(
              data: String.fromCharCodes(store.passwordHash),
              backgroundColor: Colors.white,
              size: 160,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildItem({String title, String value, Widget subtitle}) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.grey[100]),
      ),
      subtitle: subtitle ??
          Text(
            value,
            style: TextStyle(color: Colors.lime[100]),
          ),
    );
  }
}
