import 'dart:async';
import 'dart:developer';
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

  GoogleSignInAccount _googleUser;
  Future<DriveApi> _driveApiFuture;

  Future<GoogleSignInAccount> signIn() async {
    if (_googleUser == null) {
      final googleSignIn = GoogleSignIn.standard(scopes: authScopes);
      log('Signing in to google...', name: '$this');
      _googleUser = await googleSignIn.signIn();
      log('Email: ${_googleUser.email}', name: '$this');
    }
    return _googleUser;
  }

  void signOut() {
    _googleUser = null;
    _driveApiFuture = null;
  }

  Future<DriveApi> initDrive() async {
    final googleUser = await signIn();
    final authHeaders = await googleUser.authHeaders;
    log('Header: $authHeaders', name: '$this');
    final client = GoogleHttpClient(authHeaders);
    final drive = DriveApi(client);
    log('Ping request to drive', name: '$this');
    await drive.files.list(spaces: 'drive');
    return drive;
  }

  Future<DriveApi> getDrive() async {
    if (_driveApiFuture == null) {
      _driveApiFuture = initDrive();
    }
    for (int retry = 0; retry < 3; ++retry) {
      try {
        await _driveApiFuture;
        break;
      } catch (err, stack) {
        log('$err', stackTrace: stack, name: '$this');
        _driveApiFuture = initDrive();
      }
    }
    return _driveApiFuture;
  }

  // ---------------------------------------------------------------------------

  Future<File> rootFolder() {
    return _findOrCreate(rootFolderName);
  }

  Future<File> ensureFolder(String path) async {
    String description = '';
    File folder = await rootFolder();
    for (final name in (path ?? '').split('/')) {
      if (name == null || name.trim().isEmpty) continue;
      description += '/$name';
      folder = await _findOrCreate(
        name,
        parentId: folder.id,
        description: description,
      );
    }
    return folder;
  }

  Future<File> getFolder(String path) async {
    File folder = await rootFolder();
    for (final name in (path ?? '').split('/')) {
      if (name == null || name.trim().isEmpty) continue;
      folder = await _findFile(name, parentId: folder.id);
      if (folder == null) return null;
    }
    return folder;
  }

  Future<bool> hasFolder(String path) async {
    final folder = await getFolder(path);
    return folder != null && folder.description.isEmpty;
  }

  Future<void> deleteFolder(String path) async {
    final folder = await getFolder(path);
    if (folder != null && folder.description.isEmpty) {
      log("Deleting ${folder.description}", name: '$this');
      final drive = await getDrive();
      await drive.files.delete(folder.id);
    }
  }

  // ---------------------------------------------------------------------------

  Future<File> ensureFile(String path) async {
    final parts = (path ?? '').split('/');
    String name = parts.removeLast();
    if (name.isEmpty) {
      throw Exception('File name should not be empty');
    }

    File folder = await ensureFolder(parts.join('/'));
    final file = await _findOrCreate(
      name,
      parentId: folder.id,
      description: (folder.description ?? '') + '/$name',
      isFile: true,
    );
    return file;
  }

  Future<File> getFile(String path) async {
    final parts = (path ?? '').split('/');
    String name = parts.removeLast();
    if (name.isEmpty) return null;

    File folder = await getFolder(parts.join('/'));
    if (folder == null) return null;

    final file = await _findFile(
      name,
      parentId: folder.id,
    );
    return file;
  }

  Future<bool> hasFile(String filePath) async {
    final file = await getFile(filePath);
    return file != null;
  }

  Future<void> deleteFile(String filePath) async {
    final file = await getFile(filePath);
    if (file != null) {
      log("Deleting ${file.description}", name: '$this');
      final drive = await getDrive();
      await drive.files.delete(file.id);
    }
  }

  Future<List<int>> downloadFile(String filePath) async {
    final file = await getFile(filePath);
    if (file == null) {
      throw new Exception('No such file');
    }

    final drive = await getDrive();
    final Media media = await drive.files.get(
      file.id,
      downloadOptions: DownloadOptions.FullMedia,
    );

    log('Downloading ${media.length} bytes from "${file.description}"',
        name: '$this');
    final sink = List<int>();
    await media.stream.forEach((data) {
      sink.addAll(data);
    });
    //assert(media.length == sink.length);

    return sink;
  }

  Future<File> uploadFile(String filePath, Uint8List data,
      [bool tolerant = false]) async {
    try {
      final drive = await getDrive();
      final original = await ensureFile(filePath);

      final req = File();
      req.name = original.name;
      req.parents = original.parents;
      req.mimeType = 'application/x-binary';
      req.description = original.description;

      log('Uploading ${data.length} bytes to "${req.description ?? req.name}"',
          name: '$this');
      final file = await drive.files.update(
        req,
        original.id,
        uploadMedia: Media(Stream.value(data.toList()), data.length),
      );
      return file;
    } catch (err) {
      if (tolerant) return null;
      throw err;
    }
  }

  // ---------------------------------------------------------------------------

  Future<File> _findFile(String name, {String parentId}) async {
    assert(name != null && name.isNotEmpty);
    assert(!name.contains('/'));
    log('Looking for "$name"', name: '$this');

    final drive = await getDrive();
    final files = await drive.files.list(
      spaces: 'drive',
      $fields: 'files(id, name, mimeType, description, modifiedTime)',
      q: "name = '$name' and trashed = false" +
          (parentId != null ? " and '$parentId' in parents" : ""),
    );
    if (files.files.isNotEmpty) {
      return files.files.first;
    }
    return null;
  }

  Future<File> _createFile(
    String name, {
    String parentId,
    String description,
    bool isFile = false,
  }) async {
    assert(name != null && name.isNotEmpty);
    assert(!name.contains('/'));
    log('Create "${description ?? name}"', name: '$this');

    final req = File();
    req.name = name;
    req.description = description ?? '';
    if (parentId != null) {
      req.parents = [parentId];
    }
    if (isFile) {
      req.mimeType = 'application/x-binary';
    } else {
      req.mimeType = 'application/vnd.google-apps.folder';
    }
    final drive = await getDrive();
    final file = await drive.files.create(req);
    return file;
  }

  Future<File> _findOrCreate(
    String name, {
    String parentId,
    String description,
    bool isFile = false,
  }) async {
    var file = await _findFile(name, parentId: parentId);
    if (file == null) {
      log('Not found "${description ?? name}"', name: '$this');
      file = await _createFile(
        name,
        parentId: parentId,
        description: description,
        isFile: isFile,
      );
    }
    return file;
  }
}
