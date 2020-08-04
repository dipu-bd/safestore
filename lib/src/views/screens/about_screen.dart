import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/utils/to_string.dart';

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
    return BlocBuilder<StoreBloc, StoreState>(
      builder: (context, state) {
        return SafeArea(
          top: false,
          child: Scaffold(
            appBar: buildAppBar(state),
            body: buildContent(state),
          ),
        );
      },
    );
  }

  Widget buildAppBar(StoreState state) {
    return AppBar(
      title: Text(
        'About',
        style: GoogleFonts.anticSlab(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      bottom: state.syncing
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

  Widget buildContent(StoreState state) {
    return ListView(
      padding: EdgeInsets.all(10).copyWith(bottom: 50),
      children: <Widget>[
        buildItem(
          key: 'Bin ID',
          value: state.binName,
        ),
        buildItem(
          key: 'Bin checksum (MD5)',
          value: state.lastDriveMd5,
        ),
        Divider(),
        buildItem(
          key: 'Data size',
          value: formatFileSize(state.dataVolumeSize),
        ),
        buildItem(
          key: 'Data checksum (MD5)',
          value: state.lastDataMd5,
        ),
        buildItem(
          key: 'Last Synced',
          value: state.storage.lastSyncTime,
        ),
        Divider(),
        buildItem(
          key: 'Total items',
          value: state.storage.totalItems,
        ),
        buildItem(
          key: 'Labels count',
          valueBuilder: () async => state.storage.labels().length,
        ),
        buildItem(
          key: 'Visible notes count',
          valueBuilder: () async => state.storage.notes().length,
        ),
        buildItem(
          key: 'Archived notes count',
          valueBuilder: () async => state.storage.archivedNotes().length,
        ),
        Divider(),
        buildImageItem(
          title: 'Password Hash',
          subtitle: 'Never share this with anyone',
          image: Container(
            padding: EdgeInsets.only(top: 10),
            child: QrImage(
              data: String.fromCharCodes(state.passwordHash),
              backgroundColor: Colors.white,
              size: 180,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildImageItem({title, subtitle, Widget image}) {
    return ListTile(
      title: buildTitle(title),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          image,
          SizedBox(height: 5),
          buildSubtitle(subtitle),
        ],
      ),
    );
  }

  Widget buildItem({key, value, Future Function() valueBuilder}) {
    Widget title = buildTitle(key);
    Widget subtitle = buildSubtitle(value);
    if (valueBuilder != null) {
      subtitle = FutureBuilder(
        future: valueBuilder(),
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return buildErrorText('Loading...');
          }
          if (snapshot.hasError) {
            return buildErrorText(snapshot.error);
          }
          return buildSubtitle(snapshot.data);
        },
      );
    }
    return ListTile(
      title: title,
      subtitle: subtitle,
    );
  }

  Widget buildTitle(title) {
    return Text(
      '$title',
      style: TextStyle(
        color: Colors.grey[100],
      ),
    );
  }

  Widget buildSubtitle(value) {
    return Text(
      '$value',
      style: GoogleFonts.firaMono(
        color: Colors.lime[100],
      ),
    );
  }

  Widget buildErrorText(error) {
    return Text(
      '$error',
      style: GoogleFonts.firaMono(
        color: Colors.grey,
      ),
    );
  }
}
