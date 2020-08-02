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
  Future<File> _rootFolder;

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
    _rootFolder = null;
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

  Future<File> findFile(String name, {File parent}) async {
    assert(name != null && name.isNotEmpty);
    assert(!name.contains('/'));
    log('Looking for "$name"', name: '$this');

    final drive = await getDrive();
    final files = await drive.files.list(
      spaces: 'drive',
      $fields: 'files(id, name, mimeType, description, md5Checksum)',
      q: "name = '$name' and trashed = false" +
          (parent != null ? " and '${parent.id}' in parents" : ""),
    );
    if (files.files.isNotEmpty) {
      return files.files.first;
    }
    return null;
  }

  Future<File> createFile(
    String name, {
    File parent,
    bool isFile = false,
  }) async {
    assert(name != null && name.isNotEmpty);
    assert(!name.contains('/'));

    final req = File();
    req.name = name;
    req.description = "${parent.description ?? ''}/$name";
    if (parent.id != null) {
      req.parents = [parent.id];
    }
    if (isFile) {
      req.mimeType = 'application/x-binary';
    } else {
      req.mimeType = 'application/vnd.google-apps.folder';
    }

    log('Create "${req.toJson()}"', name: '$this');
    final drive = await getDrive();
    final file = await drive.files.create(req);
    return file;
  }

  Future<File> findOrCreate(
    String name, {
    File parent,
    bool isFile = false,
  }) async {
    var file = await findFile(name, parent: parent);
    if (file == null) {
      log('Not found "$name"', name: '$this');
      file = await createFile(
        name,
        parent: parent,
        isFile: isFile,
      );
    }
    return file;
  }

  Future<List<int>> downloadFile(File file) async {
    if (file == null) {
      throw new Exception('No such file');
    }
    final drive = await getDrive();
    final Media media = await drive.files.get(
      file.id,
      downloadOptions: DownloadOptions.FullMedia,
    );

    log('Get "${media.length}" bytes from "${file.description}"',
        name: '$this');
    final sink = List<int>();
    await media.stream.forEach((data) {
      sink.addAll(data);
    });
    assert(media.length == null || media.length == sink.length);

    return sink;
  }

  Future<File> uploadFile(File dest, Uint8List data,
      [bool tolerant = false]) async {
    if (dest == null) {
      throw new Exception('No such file');
    }

    final req = File();
    req.name = dest.name;
    req.parents = dest.parents;
    req.mimeType = 'application/x-binary';
    req.description = dest.description;

    log('Upload ${data.length} bytes to "${req.description}"', name: '$this');
    final drive = await getDrive();
    final file = await drive.files.update(
      req,
      dest.id,
      uploadMedia: Media(Stream.value(data.toList()), data.length),
    );
    return file;
  }

  Future<void> deleteFile(File file) async {
    if (file == null) return;
    log("Deleting ${file.description}", name: '$this');
    final drive = await getDrive();
    await drive.files.delete(file.id);
  }

  // ---------------------------------------------------------------------------

  Future<File> rootFolder() {
    if (_rootFolder == null) {
      _rootFolder = findOrCreate(rootFolderName);
    }
    return _rootFolder;
  }

  Future<File> ensureFolder(String path) async {
    File folder = await rootFolder();
    for (final name in (path ?? '').split('/')) {
      if (name == null || name.trim().isEmpty) continue;
      folder = await findOrCreate(name, parent: folder);
    }
    return folder;
  }

  Future<File> findFolder(String path) async {
    File folder = await rootFolder();
    for (final name in (path ?? '').split('/')) {
      if (name == null || name.trim().isEmpty) continue;
      folder = await findFile(name, parent: folder);
      if (folder == null) return null;
    }
    return folder;
  }

  Future<bool> hasFolder(String path) async {
    final folder = await findFolder(path);
    return folder != null;
  }

  Future<void> deleteFolder(String path) async {
    final folder = await findFolder(path);
    if (folder == null || folder.description.isEmpty) {
      return; // should not delete root folder
    }
    deleteFile(folder);
  }

  // ---------------------------------------------------------------------------

  Future<File> ensureFileByPath(String path) async {
    final parts = (path ?? '').split('/');
    String name = parts.removeLast();
    if (name.isEmpty) {
      throw Exception('File name should not be empty');
    }

    File folder = await ensureFolder(parts.join('/'));
    final file = await findOrCreate(name, parent: folder, isFile: true);
    return file;
  }

  Future<File> findFileByPath(String path) async {
    final parts = (path ?? '').split('/');
    String name = parts.removeLast();
    if (name.isEmpty) return null;

    File folder = await findFolder(parts.join('/'));
    if (folder == null) return null;

    final file = await findFile(name, parent: folder);
    return file;
  }

  Future<bool> hasFileByPath(String filePath) async {
    final file = await findFileByPath(filePath);
    return file != null;
  }

  Future<void> deleteFileByPath(String filePath) async {
    final file = await findFileByPath(filePath);
    await deleteFile(file);
  }

  Future<List<int>> downloadFileByPath(String filePath) async {
    final file = await findFileByPath(filePath);
    return downloadFile(file);
  }

  Future<File> uploadFileByPath(String filePath, Uint8List data,
      [bool tolerant = false]) async {
    final file = await ensureFileByPath(filePath);
    return await uploadFile(file, data, tolerant);
  }
}
