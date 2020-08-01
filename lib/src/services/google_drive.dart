import 'dart:async';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(BaseRequest request) =>
      super.send(request..headers.addAll(_headers));
}

class GoogleDrive {
  static final _instance = GoogleDrive._init();

  factory GoogleDrive() => _instance;

  GoogleDrive._init();

  // ---------------------------------------------------------------------------

  static final authScopes = <String>[
    'email',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
  ];
  static final rootFolderName = 'Safestore';

  Future<DriveApi> _driveApiFuture;

  Future<DriveApi> initDrive() async {
    final googleSignIn = GoogleSignIn.standard(scopes: authScopes);
    print('Signing in to google...');
    final googleUser = await googleSignIn.signIn();
    print('Email: ${googleUser.email}');
    final authHeaders = await googleUser.authHeaders;
    print('Header: $authHeaders');
    final client = GoogleHttpClient(authHeaders);
    final drive = DriveApi(client);
    return drive;
  }

  Future<DriveApi> getDrive() {
    if (_driveApiFuture == null) {
      _driveApiFuture = initDrive();
    }
    return _driveApiFuture;
  }

  // ---------------------------------------------------------------------------

  Future<File> rootFolder() {
    return _createPath(rootFolderName);
  }

  Future<File> ensureFolder(String path) async {
    final root = await rootFolder();
    final folder = await _createPath(path, parent: root);
    return folder;
  }

  Future<void> deleteFolder(String path) async {
    final folder = await ensureFolder(path);
    print("Deleting ${folder.name}");
    final drive = await getDrive();
    await drive.files.delete(folder.id);
  }

  // ---------------------------------------------------------------------------

  Future<File> ensureFile(String path) async {
    final root = await rootFolder();
    final file = await _createPath(path, parent: root, isFile: true);
    return file;
  }

  Future<void> deleteFile(String filePath) async {
    final file = await ensureFile(filePath);
    print("Deleting ${file.name}");
    final drive = await getDrive();
    await drive.files.delete(file.id);
  }

  Future<Uint8List> downloadFile(String filePath) async {
    final file = await ensureFile(filePath);
    final drive = await getDrive();
    final Media media = await drive.files.get(
      file.id,
      downloadOptions: DownloadOptions.FullMedia,
    );
    final sink = List<int>();
    await media.stream.forEach((data) {
      sink.addAll(data);
    });
    return Uint8List.fromList(sink);
  }

  Future<File> uploadFile(String filePath, List<int> data) async {
    final drive = await getDrive();
    final original = await ensureFile(filePath);
    final req = File();
    req.name = original.name;
    req.parents = original.parents;
    req.mimeType = 'application/x-binary';
    req.description = original.description;
    final file = await drive.files.update(
      req,
      original.id,
      uploadMedia: Media(Stream.value(data), data.length),
    );
    return file;
  }

  // ---------------------------------------------------------------------------

  Future<File> _createPath(
    String path, {
    File parent,
    bool isFile = false,
  }) async {
    // Get instance of drive api
    final drive = await getDrive();

    String description = '/${parent?.name ?? ''}';
    final parts = (path ?? '')
        .split('/')
        .reversed
        .skipWhile((value) => value == null && value.isEmpty)
        .toList();
    while (parts.isNotEmpty) {
      final name = parts.removeLast();
      final isLast = parts.isEmpty;
      description = "$description/$name";

      // find this file
      final files = await drive.files.list(
        spaces: 'drive',
        q: "name = '$name' and trashed = false" +
            (parent != null ? " and '${parent.id}' in parents" : ""),
      );

      // take it if already exists, or create new
      if (files.files.isNotEmpty) {
        parent = files.files.first;
      } else {
        print('Create $description');
        final req = File();
        req.name = name;
        req.description = description;
        if (parent != null) {
          req.parents = [parent.id];
        }
        req.mimeType = isLast && isFile
            ? 'application/x-binary'
            : 'application/vnd.google-apps.folder';
        parent = await drive.files.create(req);
      }
    }
    return parent;
  }
}
