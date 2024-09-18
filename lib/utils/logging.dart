import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class Logging {

  static Future<String> get _localPath async {
    if (Platform.isWindows) {
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path + '/carwash';
      new Directory(tempPath).create(recursive: true);
      return tempPath;
    } else if (Platform.isAndroid || Platform.isIOS) {
      //Get external storage directory
      var directory = await getExternalStorageDirectory();
      //Check if external storage not available. If not available use
      //internal applications directory
      directory ??= await getApplicationDocumentsDirectory();
      return directory.path;
    }
    return '';
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/log.txt');
  }

  static Future<File> write(String data) async {
    final file = await _localFile;
    // Write the file in append mode so it would append the data to
    //existing file
    String dt = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    String log = '$dt $data\n';
    print(log);
    return file.writeAsString(log, mode: FileMode.append);
  }
}