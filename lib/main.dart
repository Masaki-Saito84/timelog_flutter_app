import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'work_logs.dart';
import 'breaks.dart';

String dateFormat(DateTime date) {
  final outputFormat = DateFormat('yyyy/MM/dd(E) HH:mm:ss');
  return outputFormat.format(date);
}

String purseableDateFormat (DateTime date) {
  final purseableFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  return purseableFormat.format(date);
}

class ProceedingStore extends ChangeNotifier {
  String? duty;

  ProceedingStore() {
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
  WorkLogs attend = WorkLogs(
    new DateTime(1),
    new DateTime(1),
    [
      Breaks(
        new DateTime(1),
        new DateTime(1),
      )
    ],
  );

  OnDutyStateNotifier() {
    init();
  }

  void init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('work_logs') == null) {
      attend = WorkLogs(
        new DateTime(1),
        new DateTime(1),
        [
          Breaks(
            new DateTime(1),
            new DateTime(1),
          )
        ],
      );
      prefs.setString('work_logs', json.encode(attend.toJson()));
    } else {
      final decodePrefs =
          await json.decode(prefs.getString('work_logs').toString());
      final String start = await decodePrefs['start'];
      final String end = await decodePrefs['end'];
      final List<Breaks> breaks = await decodePrefs['breaks']
          .map<Breaks>((breakInfo) => new Breaks(
              DateTime.parse(breakInfo['start']),
              DateTime.parse(breakInfo['end'])))
          .toList();

      attend = WorkLogs(DateTime.parse(start), DateTime.parse(end), breaks);
    }
    notifyListeners();
  }

  void addStartTime() {
    attend.start = DateTime.now();
    notifyListeners();
    setPrefs();
  }

  void addEndTime() {
    attend.end = DateTime.now();
    notifyListeners();
    setPrefs();
  }

  void addBreakStartTime() {
    attend.breaks.forEach((acquiredBreak) {
      if (acquiredBreak.start.year == 1) {
        acquiredBreak.start = DateTime.now();
        setPrefs();
        notifyListeners();
      }
    });
  }

  void addBreakEndTime() {
    attend.breaks.forEach((acquiredBreak) {
      if (acquiredBreak.end.year == 1) {
        acquiredBreak.end = DateTime.now();
      }
    });
    attend.breaks.add(Breaks(new DateTime(1), new DateTime(1)));
    setPrefs();
    notifyListeners();
  }

  void setPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('work_logs', json.encode(attend.toJson()));
  }

  void reset() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('work_logs');
    init();
    notifyListeners();
  }
}

Widget timeRow(String label, DateTime date) {
  final outputDate = dateFormat(date);
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
        ChangeNotifierProvider<ProceedingStore>(
          create: (context) => ProceedingStore(),
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
  String _time = '';

  var swatch = Stopwatch();
  final duration = Duration(seconds: 1);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProceedingStore, OnDutyStateNotifier>(builder: (context, proceedingStore, onDutyState, _) {
      WorkLogs attend = onDutyState.attend;
      bool isBreak = attend.breaks.any((acquiredBreak) =>
          acquiredBreak.start.year != 1 && acquiredBreak.end.year == 1);
      bool isRecord = attend.start.year != 1;
      bool isResult = proceedingStore.duty == 'off' && attend.end.year != 1;
      String _headTitle = '';

      if (proceedingStore.duty == 'on') {
        _headTitle = '勤務中';
        if (isBreak) {
          _headTitle = '休憩中';
        }
      } else {
        if (isResult) {
          _headTitle = DateFormat('yyyy/M/d (E)').format(attend.start);
        } else {
          _headTitle = DateFormat('yyyy/M/d (E)').format(DateTime.now());
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(_headTitle),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (proceedingStore.duty == 'on') Text('勤務時間'),
            if (isResult) Text('勤務時間\n' + totalDuty(attend)),
            if (isRecord) timeRow('開始時刻', attend.start),
            if (isResult) timeRow('終了時刻', attend.end),
            if (!isRecord && proceedingStore.duty == 'off')
              Text('業務開始時に右下のボタンを押してください'),
            if (isRecord || isResult)
              Expanded(
                  child: ListView.builder(
                      itemCount: attend.breaks.length,
                      itemBuilder: (BuildContext context, int index) {
                        final DateTime breakStart = attend.breaks[index].start;
                        final DateTime breakEnd = attend.breaks[index].end;
                        bool isInitBreak =
                            breakStart.year == 1 && breakEnd.year == 1;
                        if (!isInitBreak) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isBreak) Text('休憩中'),
                              if (isResult && index == 0)
                                Text('総休憩時間\n' +
                                    totalBreaks(attend.breaks, true)),
                              Text('休憩' + (index + 1).toString()),
                              timeRow('開始時刻', breakStart),
                              if (breakEnd.year != 1) timeRow('終了時刻', breakEnd),
                            ],
                          );
                        } else if (isResult) {
                          return ElevatedButton(
                            child: Text(
                              '休憩記録を追加',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1,
                              ),
                            ),
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 26),
                            ),
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      })),
          ],
        ),
        floatingActionButton: Container(
            child: Column(
          verticalDirection: VerticalDirection.up,
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: () {
                if (!isRecord) {
                  proceedingStore.setDuty('on');
                  onDutyState.addStartTime();
                } else if (isResult) {
                  onDutyState.reset();
                } else {
                  proceedingStore.setDuty('off');
                  onDutyState.addEndTime();
                  if (isBreak) {
                    onDutyState.addBreakEndTime();
                  }
                }
              },
              tooltip: 'WorkStateToggle',
              child: (() {
                if (!isRecord) {
                  return Icon(Icons.play_arrow);
                } else if (isResult) {
                  return Icon(Icons.restart_alt);
                } else {
                  return Icon(Icons.stop);
                }
              })(),
            ),
            if (proceedingStore.duty == 'on')
              Container(
                margin: EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    if (isBreak) {
                      onDutyState.addBreakEndTime();
                    } else {
                      onDutyState.addBreakStartTime();
                    }
                  },
                  child: (() {
                    if (isBreak) {
                      return Icon(Icons.alarm_on);
                    } else {
                      return Icon(Icons.alarm_add);
                    }
                  })(),
                ),
              )
          ],
        )),
      );
    });
  }

  totalBreaks(List<Breaks> breakLog, [bool toString = false]) {
    var totalDuration;

    breakLog.asMap().forEach((index, breakInfo) {
      final DateTime start = breakInfo.start;
      final DateTime end = breakInfo.end;
      final duration = end.difference(start);
      if (index == 0) {
        totalDuration = duration;
      } else {
        totalDuration += duration;
      }
    });

    if (toString) {
      return totalDuration.toString().split('.').first.padLeft(8, "0");
    }
    return totalDuration;
  }

  String totalDuty(WorkLogs workLog) {
    final DateTime start = workLog.start;
    final DateTime end = workLog.end;
    final List<Breaks> breaks = workLog.breaks;
    var totalDuration = end.difference(start);

    if (!breaks
        .every((breaks) => breaks.start.year == 1 && breaks.end.year == 1)) {
      totalDuration -= totalBreaks(breaks);
    }
    return totalDuration.toString().split('.').first.padLeft(8, "0");
  }

  @override
  void startTimer() {
    Timer(duration, keepRunning);
  }

  void keepRunning() {
    if (swatch.isRunning) {
      startTimer();
    }
    // setState(() {
    //   _time = swatch.elapsed.inHours.toString().padLeft(2,"0") +':'
    //     + (swatch.elapsed.inMinutes%60).toString().padLeft(2,"0") +':'
    //     + (swatch.elapsed.inSeconds%60).toString().padLeft(2,"0");
    // });
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
  }

  void allTimeClear() {
    swatch.reset();
  }
}
