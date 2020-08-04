import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/blocs/store_bloc.dart';
import 'package:safestore/src/services/google_drive.dart';
import 'package:safestore/src/utils/converters.dart';

class CounterCubit extends Cubit<int> {
  bool closed = false;

  CounterCubit() : super(0) {
    loop();
  }

  @override
  Future<void> close() {
    closed = true;
    return super.close();
  }

  void loop() async {
    while (!closed) {
      await Future.delayed(Duration(seconds: 1));
      emit(state + 1);
    }
  }
}

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
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: BlocBuilder<CounterCubit, int>(
        builder: (context, state) {
          return SafeArea(
            top: false,
            child: Scaffold(
              appBar: buildAppBar(context),
              body: buildContent(context),
            ),
          );
        },
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    final store = StoreBloc.of(context).state;
    return AppBar(
      title: Text(
        'System Info',
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
    final auth = AuthBloc.of(context).state;
    final store = StoreBloc.of(context).state;
    return ListView(
      padding: EdgeInsets.all(10).copyWith(bottom: 50),
      children: <Widget>[
        buildItem(
          key: 'Total items',
          value: store.notes.length,
        ),
        buildItem(
          key: 'Labels count',
          value: store.labels.length,
        ),
        buildItem(
          key: 'Visible notes count',
          value: store.notes.values.where((note) => !note.isArchived).length,
        ),
        buildItem(
          key: 'Archived notes count',
          value: store.notes.values.where((note) => note.isArchived).length,
        ),
        Divider(),
        buildItem(
          key: 'Last Synced',
          value: formatDuration(DateTime.now().difference(store.lastSyncAt)),
        ),
        buildItem(
          key: 'Data size (compressed)',
          value: formatFileSize(store.dataVolumeSize),
        ),
        buildItem(
          key: 'Data checksum (MD5)',
          value: store.lastDataMd5,
        ),
        Divider(),
        buildItem(
          key: 'Bin ID',
          value: store.binName,
        ),
        buildItem(
          key: 'Bin checksum (MD5)',
          value: store.lastBinMd5,
        ),
        buildItem(
          key: 'Bin file version',
          value: store.binFile?.version,
        ),
        buildItem(
          key: 'Bin file size',
          value: formatFileSize(double.tryParse(store.binFile?.size)),
        ),
        Divider(),
        buildImageItem(
          title: 'Password Hash',
          subtitle: 'Never share this with anyone',
          image: Container(
            padding: EdgeInsets.only(top: 10),
            child: QrImage(
              data: String.fromCharCodes(store.passwordHash),
              backgroundColor: Colors.white,
              size: 180,
            ),
          ),
        ),
        Divider(),
        buildItem(
          key: 'Google Drive user',
          value: auth.username,
        ),
        buildItem(
          key: 'Email address',
          value: auth.email,
        ),
        buildItem(
          key: 'Backup folder in Google Drive',
          value: GoogleDrive.rootFolderName,
        ),
        buildItem(
          key: 'Authentication',
          value: auth.authHeaders,
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
          buildSubtitle(subtitle, 12),
        ],
      ),
    );
  }

  Widget buildItem({key, value, Future Function() future}) {
    Widget title = buildTitle(key);
    Widget subtitle = buildSubtitle(value);
    if (future != null) {
      subtitle = FutureBuilder(
        future: future(),
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

  Widget buildSubtitle(value, [double fontSize]) {
    return Text(
      '$value',
      style: GoogleFonts.firaMono(
        color: Colors.lime[100],
        fontSize: fontSize,
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
