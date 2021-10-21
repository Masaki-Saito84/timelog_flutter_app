import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'work_logs.dart';
import 'breaks.dart';

String outputDateFormat(DateTime date) {
  final outputFormat = DateFormat('yyyy/MM/dd(E) HH:mm:ss');
  return outputFormat.format(date);
}

String purseableDateFormat (DateTime date) {
  final purseableFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  return purseableFormat.format(date);
}

class DutyStore extends ChangeNotifier {
  String? duty;

  DutyStore() {
    init();
  }

  void init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('duty') == null) {
      duty = 'off';
      prefs.setString('duty', 'off');
    } else {
      duty = prefs.getString('duty');
    }
    notifyListeners();
  }

  void setDuty(String state) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    duty = state;
    prefs.setString('duty', state);
    notifyListeners();
  }

}

class OnDutyStateNotifier extends ChangeNotifier {
  Map<String, dynamic> attend = {};

  OnDutyStateNotifier() {
    init();
  }

  void init() {
    attend = {
      'start': '',
      'end': '',
      'breaks': [],
    };
  }

  void addStartTime() {
    attend['start'] = nowTime();
    notifyListeners();
  }

  void addEndTime() {
    attend['end'] = nowTime();
    notifyListeners();
  }

  void reset() {
    init();
    notifyListeners();
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DutyStore>(
          create: (context) => DutyStore(),
        ),
        ChangeNotifierProvider<OnDutyStateNotifier>(
          create: (context) => OnDutyStateNotifier(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: WorkLog(),
      ),
    ),
  );
}

class WorkLog extends StatelessWidget {
  String _headTitle = '';
  String _time = '';

  var swatch = Stopwatch();
  final duration = Duration(seconds: 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_headTitle),
      ),
      body: Center(
        child: Consumer2<DutyStore, OnDutyStateNotifier>(builder: (context, dutyStore, onDutyState, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if(onDutyState.attend['start'] != '') Text('勤務時間'),
              if(onDutyState.attend['start'] != '') Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '開始時刻\n' + onDutyState.attend['start'],
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
              if(!dutyStore.duty && onDutyState.attend['end'] != '') Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '終了時刻\n' + onDutyState.attend['end'],
                  ),
                  if (onDutyState.attend['end'] != '') ElevatedButton(
                    child: Text(
                      '勤務終了時間 編集',
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
              if(onDutyState.attend['start'] == '') Text('業務開始時に右下のボタンを押してください')
            ],
          );
        })
      ),
      floatingActionButton: Container(
        child: Consumer2<DutyStore, OnDutyStateNotifier>(builder: (context, dutyStore, onDutyState,  _) {
          return Column(
            verticalDirection: VerticalDirection.up,
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: () {
                  if(onDutyState.attend['start'] == '') {
                    dutyStore.setDuty('on');
                    onDutyState.addStartTime();
                  } else if(onDutyState.attend['start'] != '' && onDutyState.attend['end'] != '') {
                    onDutyState.reset();
                  } else {
                    dutyStore.setDuty('off');
                    onDutyState.addEndTime();
                  }
                },
                tooltip: 'WorkStateToggle',
                child: (() {
                  if(onDutyState.attend['start'] == '') {
                    return Icon(Icons.play_arrow);
                  } else if(onDutyState.attend['start'] != '' && onDutyState.attend['end'] != '') {
                    return Icon(Icons.restart_alt);
                  } else {
                    return Icon(Icons.stop);
                  }
                }) (),
              ),
              if(dutyStore.duty) Container(
                margin: EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  onPressed: () {},
                  child: (() {
                    return Icon(Icons.alarm_add);
                  })(),
                ),
              )
            ],
          );
        }),
      )
    );
  }

  @override
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
    _time = '00:00:00';
    swatch.start();
    startTimer();
  }
  void setWorkEndTime() {
    var now = DateTime.now();
    swatch.stop();
    var workEndHeadTitle = _headTitle + ' 勤務詳細';
  }
  void allTimeClear() {
    swatch.reset();
  }
}
