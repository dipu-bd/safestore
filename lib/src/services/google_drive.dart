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
  static final rootFolderName = 'Safestore';
  static final authScopes = <String>[
    'email',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  DriveApi drive;
  Map<String, String> user = {};
  Map<String, String> authHeaders = {};
  File rootFolder;

  static Future<GoogleDrive> signIn() async {
    final instance = GoogleDrive();
    await instance.refreshToken();
    return instance;
  }

  Future<void> refreshToken() async {
    final googleSignIn = GoogleSignIn.standard(scopes: authScopes);
    log('Signing in to google...');
    final googleUser = await googleSignIn.signIn();
    user = {
      'id': googleUser.id,
      'email': googleUser.email,
      'name': googleUser.displayName,
      'image': googleUser.photoUrl,
    };
    log('User: $user');
    authHeaders = await googleUser.authHeaders;
    log('Headers: $authHeaders');
    initDrive();
    return drive;
  }

  Future<void> initDrive() async {
    drive = DriveApi(GoogleHttpClient(authHeaders));
    rootFolder = await findOrCreate(rootFolderName);
    log('Root folder id: ${rootFolder.id}');
  }

  // ---------------------------------------------------------------------------

  Future<File> findFile(String name, {File parent}) async {
    assert(name != null && name.isNotEmpty);
    assert(!name.contains('/'));
    log('Looking for "$name" in ${parent?.name}', name: '$this');
    final files = await drive.files.list(
      spaces: 'drive',
      $fields: '*',
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
    final file = await drive.files.create(
      req,
      $fields: '*',
    );
    return file;
  }

  Future<File> findOrCreate(
    String name, {
    File parent,
    bool isFile = false,
  }) async {
    var file = await findFile(name, parent: parent);
    if (file == null) {
      log('Not found "$name" in ${parent?.name}', name: '$this');
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
    final Media media = await drive.files.get(
      file.id,
      downloadOptions: DownloadOptions.FullMedia,
    );

    log('Get "${media.length}" bytes from "${file.name}"', name: '$this');
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

    log('Upload ${data.length} bytes to "${dest.name}"', name: '$this');
    final file = await drive.files.update(
      File(),
      dest.id,
      $fields: '*',
      uploadMedia: Media(Stream.value(data.toList()), data.length),
    );
    return file;
  }

  Future<void> deleteFile(File file) async {
    if (file == null) return;
    log("Deleting ${file.name}", name: '$this');
    await drive.files.delete(file.id);
  }

  // ---------------------------------------------------------------------------

  Future<File> ensureFolder(String path) async {
    File folder = rootFolder;
    for (final name in (path ?? '').split('/')) {
      if (name == null || name.trim().isEmpty) continue;
      folder = await findOrCreate(name, parent: folder);
    }
    return folder;
  }

  Future<File> findFolder(String path) async {
    File folder = rootFolder;
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
