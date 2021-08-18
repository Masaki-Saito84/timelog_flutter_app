import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WorkingHour(title: 'Flutter Demo Home Page'),
    );
  }
}

class WorkingHour extends StatefulWidget {
  WorkingHour({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _WorkingHour createState() => _WorkingHour();
}

class _WorkingHour extends State<WorkingHour> {
  String _workStartTime = '';
  String _workEndTime = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_workStartTime != '')
              Text(
                '開始時刻\n$_workStartTime',
              ),
            if (_workStartTime != '')
              Text(
                '労働時間\n$_time',
              ),
            if (_workEndTime != '')
              Text(
                '終了時刻\n$_workEndTime',
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if(_workStartTime == '') {
            setWorkStartTime();
          } else {
            setWorkEndTime();
          }
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  void setWorkStartTime() {
    var now = DateTime.now();
    var dateFormat = DateFormat('yyyy/MM/dd(E)\nHH:mm');
    var timeString = dateFormat.format(now);
    setState(() {
      _workStartTime = timeString;
    });
  }
  void setWorkEndTime() {
    var now = DateTime.now();
    var dateFormat = DateFormat('yyyy/MM/dd(E)\nHH:mm');
    var timeString = dateFormat.format(now);
    setState(() {
      _workEndTime = timeString;
    });
  }
}
