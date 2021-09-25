// pdf: ^3.6.0
//   path_provider:
//   flutter_full_pdf_viewer:
//   downloads_path_provider_28:
//   permission_handler:
//   open_file:
//   flutter_local_notifications:


import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as path;

// import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class MyPDF extends StatefulWidget {
  @override
  _MyPDFState createState() => _MyPDFState();
}

class _MyPDFState extends State<MyPDF> {
  final pdf = pw.Document();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String _progress = "";

  @override
  void initState() {
    try {
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final android = AndroidInitializationSettings('@mipmap/ic_launcher');
      final iOS = IOSInitializationSettings();
      final initSettings = InitializationSettings(android: android, iOS: iOS);
      flutterLocalNotificationsPlugin.initialize(initSettings,
          onSelectNotification: _onSelectNotification);
    } catch (e) {
      print(e.toString());
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Container(
                margin: EdgeInsets.only(top: 30),
                height: 40,
                child: RaisedButton(
                    shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(5.0),
                    ),
                    child: Text(
                      'Get Report',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    color: Colors.blue,
                    onPressed: () {
                      createAndSavePdf();
                    }))));
  }

  createAndSavePdf() async {
    final dir = await _getDownloadDirectory();
    final isPermissionStatusGranted = await _requestPermissions();

    if (isPermissionStatusGranted) {
      final savePath = dir!.path;
      await _startDownload(
        savePath,
      );
    } else {
      print('perission denied');
    }
  }

  createPdf() async {
    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) =>
            pw.Container(height: 200, width: 200, child: pw.Text('DG'))));
  }

  Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return await DownloadsPathProvider.downloadsDirectory;
    }
  }

  Future<bool> _requestPermissions() async {
    // final Permission _permission;
    var permission = await [
      Permission.storage,
    ].request();
    // print(permission.values.first);
    if (permission.values.first != PermissionStatus.granted) {
      // print(permission.values.first);
      permission = await [
        Permission.storage,
      ].request();
    }
    return permission.values.first == PermissionStatus.granted;
  }

  Future<void> _startDownload(
    String savePath,
  ) async {
    Map<String, dynamic> result = {
      'isSuccess': false,
      'filePath': null,
      'error': null,
    };

    try {
      createPdf();
      final String filePath = '$savePath/dg.pdf';
      final File file = File.fromUri(Uri.parse(filePath));
      file.writeAsBytesSync(await pdf.save());
      result['isSuccess'] = true;
      result['filePath'] = filePath;
      print(filePath);
    } catch (ex) {
      print(ex);
      result['error'] = ex.toString();
    } finally {
      await _showNotification(result);
    }
  }

  void _onReceiveProgress(int received, int total) {
    if (total != -1) {
      setState(() {
        // _progress = (received / total * 100).toStringAsFixed(0) + "%";
      });
    }
  }

  Future<void> _showNotification(Map<String, dynamic> downloadStatus) async {
    final android = AndroidNotificationDetails(
        'channel id', 'channel name', 'channel description',
        priority: Priority.high, importance: Importance.max);
    final iOS = IOSNotificationDetails();
    final platform = NotificationDetails(android: android, iOS: iOS);
    final json = jsonEncode(downloadStatus);
    final isSuccess = downloadStatus['isSuccess'];

    await flutterLocalNotificationsPlugin.show(
        0, // notification id
        isSuccess ? 'Success' : 'Failure',
        isSuccess
            ? 'File has been downloaded successfully!'
            : 'There was an error while downloading the file.',
        platform,
        payload: json);
  }

  Future _onSelectNotification(String? json) async {
    final obj = jsonDecode(json!);

    if (obj['isSuccess']) {
      OpenFile.open(obj['filePath']);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('${obj['error']}'),
        ),
      );
    }
  }
}
