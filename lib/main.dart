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
  String _time = '';
  var swatch = Stopwatch();
  final duration = Duration(seconds: 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: (
          () {
            if (_workStartTime != '') {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('労働時間\n$_time'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '開始時刻\n$_workStartTime',
                          ),
                          ElevatedButton(
                            child: Text(
                              '勤務開始時間 編集',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1,
                              ),
                            ),
                            onPressed: () {
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 26),
                            ),
                          )
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _workEndTime != '' ? '終了時刻\n' + _workEndTime : '終了時刻\n' + getNowDate() + '\n--:--'
                          ),
                          ElevatedButton(
                            child: Text(
                              '勤務終了時間 編集',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1,
                              ),
                            ),
                            onPressed: _workEndTime == '' && _workStartTime != '' ? null : () {
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 26),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ],
              );
            } else {
              return Text('業務開始時に右下のボタンを押してください');
            }
          }()
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if(_workStartTime == '') {
            setWorkStartTime();
          } else if(_workStartTime != '' && _workEndTime != '') {
            allTimeClear();
          } else {
            setWorkEndTime();
          }
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  void startTimer() {
    Timer(duration, keepRunning);
  }
  void keepRunning() {
    if(swatch.isRunning) {
      startTimer();
    }
    setState(() {
      _time = swatch.elapsed.inHours.toString().padLeft(2,"0") +':'
        + (swatch.elapsed.inMinutes%60).toString().padLeft(2,"0") +':'
        + (swatch.elapsed.inSeconds%60).toString().padLeft(2,"0");
    });
  }
  void setWorkStartTime() {
    var now = DateTime.now();
    var dateFormat = DateFormat('yyyy/MM/dd(E)\nHH:mm');
    var timeString = dateFormat.format(now);
    _time = '00:00:00';
    swatch.start();
    startTimer();
    setState(() {
      _workStartTime = timeString;
    });
  }
  void setWorkEndTime() {
    var now = DateTime.now();
    var dateFormat = DateFormat('yyyy/MM/dd(E)\nHH:mm');
    var timeString = dateFormat.format(now);
    swatch.stop();
    setState(() {
      _workEndTime = timeString;
    });
  }
  void allTimeClear() {
    swatch.reset();
    setState(() {
      _workStartTime = '';
      _workEndTime = '';
      _time = '';
    });
  }
}
