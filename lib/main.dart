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
  var attend;

  OnDutyStateNotifier() {
    init();
  }

  void init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getString('work_logs') == null) {
      attend = WorkLogs('','', [Breaks('', '',)],);
      prefs.setString('work_logs', json.encode(attend!.toJson()));
    } else {
      final decodePrefs = json.decode(prefs.getString('work_logs').toString());
      attend = WorkLogs(decodePrefs['start'], decodePrefs['end'], [Breaks(decodePrefs['breaks'][0]['start'], decodePrefs['breaks'][0]['start'])]);
    }
  }

  void addStartTime() {
    attend!.start = purseableDateFormat(DateTime.now());
    notifyListeners();
    setPrefs();
  }

  void addEndTime()  {
    attend!.end = purseableDateFormat(DateTime.now());
    notifyListeners();
    setPrefs();
  }

  void addBreakStartTime() {
    attend!.breaks.forEach((acquiredBreak) {
      if (acquiredBreak.start == '') {
        acquiredBreak.start = purseableDateFormat(DateTime.now());
        setPrefs();
        notifyListeners();
      }
    });
  }

  void addBreakEndTime() {
    attend!.breaks.forEach((acquiredBreak) {
      if (acquiredBreak.end == '') {
        acquiredBreak.end = purseableDateFormat(DateTime.now());
      }
    });
    attend!.breaks.add(Breaks('', ''));
    setPrefs();
    notifyListeners();
  }

  void setPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('work_logs', json.encode(attend!.toJson()));
    final decodePrefs = json.decode(prefs.getString('work_logs').toString());
  }

  void reset() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('work_logs');
    init();
    notifyListeners();
  }
}

Widget timeRow(String label, String date) {
  final parseDate = DateTime.parse(date);
  final outputDate = outputDateFormat(parseDate);
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label + '\n' + outputDate),
      ElevatedButton(
        child: Text(
          '編集',
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
  );
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
      builder: (context, _) {
        return MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: WorkLog(),
        );
      },
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
              if(onDutyState.attend.start != '') Text('勤務時間'),
              if(onDutyState.attend.start != '') timeRow('開始時刻', onDutyState.attend!.start.toString()),
              if(dutyStore.duty == 'off' && onDutyState.attend!.end != '') timeRow('終了時刻', onDutyState.attend!.end.toString()),
              if(onDutyState.attend!.start == '' && dutyStore.duty == 'off') Text('業務開始時に右下のボタンを押してください'),
              if(!onDutyState.attend!.breaks.every((acquiredBreak) => acquiredBreak.start == '' && acquiredBreak.end == '')) Expanded(
                child: ListView.builder(
                  itemCount: onDutyState.attend!.breaks.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (!(onDutyState.attend!.breaks[index].start.toString() =='' && onDutyState.attend!.breaks[index].end.toString() == '')) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '休憩' + (index + 1).toString(),
                            style: TextStyle(
                              fontSize: 12,
                              height: 1,
                            ),
                          ),
                          timeRow('開始時刻', onDutyState.attend!.breaks[index].start.toString()),
                          if(onDutyState.attend!.breaks[index].end.toString() == '') Text('休憩中'),
                          if(onDutyState.attend!.breaks[index].end.toString() != '') timeRow('終了時刻', onDutyState.attend!.breaks[index].end.toString()),
                        ],
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }
                )
              ),
            ],
          );
        })
      ),
      floatingActionButton: Container(
        child: Consumer2<DutyStore, OnDutyStateNotifier>(builder: (context, dutyStore, onDutyState,  _) {
          bool onBreak = onDutyState.attend!.breaks.any((acquiredBreak) => acquiredBreak.start != '' && acquiredBreak.end == '');
          return Column(
            verticalDirection: VerticalDirection.up,
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: () {
                  if(onDutyState.attend!.start == '') {
                    dutyStore.setDuty('on');
                    onDutyState.addStartTime();
                  } else if(onDutyState.attend!.start != '' && onDutyState.attend!.end != '') {
                    onDutyState.reset();
                  } else {
                    dutyStore.setDuty('off');
                    onDutyState.addEndTime();
                    if (onBreak) {
                      onDutyState.addBreakEndTime();
                    }
                  }
                },
                tooltip: 'WorkStateToggle',
                child: (() {
                  if(onDutyState.attend!.start == '') {
                    return Icon(Icons.play_arrow);
                  } else if(onDutyState.attend!.start != '' && onDutyState.attend!.end != '') {
                    return Icon(Icons.restart_alt);
                  } else {
                    return Icon(Icons.stop);
                  }
                }) (),
              ),
              if(dutyStore.duty == 'on') Container(
                margin: EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    if (onBreak) {
                      onDutyState.addBreakEndTime();
                    } else {
                      onDutyState.addBreakStartTime();
                    }
                  },
                  child: (() {
                    if (onBreak) {
                      return Icon(Icons.alarm_on);
                    } else {
                      return Icon(Icons.alarm_add);
                    }
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
