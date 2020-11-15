import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:provider/provider.dart';

import '../services/DownloadsProvider.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DownloadsProvider downloadsProvider =
        Provider.of<DownloadsProvider>(context, listen: false);

    return Scaffold(
        appBar: AppBar(
          title: Text("Downloads"),
        ),
        body: Consumer<DownloadsProvider>(
          builder: (context, value, child) {
            return DownloadCardList();
          },
        ));
  }
}

class DownloadCardList extends StatefulWidget {
  DownloadCardList({Key key}) : super(key: key);

  @override
  _DownloadCardListState createState() => _DownloadCardListState();
}

class _DownloadCardListState extends State<DownloadCardList> {
  ReceivePort _port = ReceivePort();
  List<_DownloadingItemData> downloadList = [];

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      _DownloadingItemData itemData =
          _DownloadingItemData(data[0], data[1], data[2]);

      bool itemExists = false;
      int index = 0;
      for (_DownloadingItemData listItem in downloadList) {
        if (listItem.id == itemData.id) {
          itemExists = true;
          downloadList[index] = itemData;
          setState(() {});
          break;
        }
        index++;
      }

      if (!itemExists) {
        downloadList.add(itemData);
        setState(() {});
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${downloadList.length} downloads"),
              DownloadStatuses(downloadList: downloadList)
            ],
          )
        ],
      ),
    );
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }
}

class DownloadCard extends StatelessWidget {
  const DownloadCard({Key key, @required this.item}) : super(key: key);

  final DownloadTask item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text("test"),
    );
  }
}

class _DownloadingItemData {
  final String id;
  final DownloadTaskStatus status;
  final int progress;

  _DownloadingItemData(this.id, this.status, this.progress);

  @override
  String toString() {
    return [id, status, progress].toString();
  }
}

class DownloadStatuses extends StatelessWidget {
  const DownloadStatuses({Key key, @required this.downloadList})
      : super(key: key);

  final List<_DownloadingItemData> downloadList;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.end,
      text: TextSpan(style: TextStyle(color: Colors.grey), children: <TextSpan>[
        TextSpan(
            text:
                "${downloadList.where((element) => element.status == DownloadTaskStatus.running).length} running\n"),
        TextSpan(
            text:
                "${downloadList.where((element) => element.status == DownloadTaskStatus.complete).length} complete\n"),
        TextSpan(
            text:
                "${downloadList.where((element) => element.status == DownloadTaskStatus.failed).length} failed")
      ]),
    );
  }
}
