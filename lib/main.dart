import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'dart:convert';
import 'work_logs.dart';
import 'breaks.dart';

String dateFormat(DateTime date) {
  final outputFormat = DateFormat('yyyy/MM/dd(E) HH:mm:ss');
  return outputFormat.format(date);
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

class WorkLogStateNotifier extends ChangeNotifier {
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

  WorkLogStateNotifier() {
    init();
  }

  void init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('work_logs') == null) {
      attend = WorkLogs(
        null,
        null,
        [],
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
    attend.breaks.add(Breaks(DateTime.now(), null));
    setPrefs();
    notifyListeners();
  }

  void addBreakEndTime() {
    attend.breaks.forEach((acquiredBreak) {
      if (acquiredBreak.end == null) {
        acquiredBreak.end = DateTime.now();
      }
    });
    setPrefs();
    notifyListeners();
  }

  void editTime(String target, DateTime editedTime) {
    if (target == 'start') {
      attend.start = editedTime;
    } else {
      attend.end = editedTime;
    }
    setPrefs();
    notifyListeners();
  }

  void editBreakTime(String target, DateTime editedTime, int? index) {
    if (index == null) {
      if (target == 'start') {
        attend.breaks.add(Breaks(editedTime, null));
      } else {
        final targetBreakInfo =
            attend.breaks.where((breakInfo) => breakInfo.end == null);
      }
    } else {
      if (target == 'start') {
        attend.breaks[index].start = editedTime;
      } else {
        attend.breaks[index].end = editedTime;
      }
    }
    setPrefs();
    notifyListeners();
  }

  void addBreakCancel() {
    attend.breaks.removeWhere((breakInfo) => breakInfo.end == null);
    setPrefs();
    notifyListeners();
  }

  void breakDelete(int index) {
    attend.breaks.remove(attend.breaks[index]);
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

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProceedingStore>(
          create: (context) => ProceedingStore(),
        ),
        ChangeNotifierProvider<WorkLogStateNotifier>(
          create: (context) => WorkLogStateNotifier(),
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
    return Consumer2<ProceedingStore, WorkLogStateNotifier>(
        builder: (context, proceedingStore, workLogState, _) {
      WorkLogs attend = workLogState.attend;
      bool isBreak =
          attend.breaks.any((acquiredBreak) => acquiredBreak.end == null);
      bool isRecord = attend.start != null;
      bool isResult = proceedingStore.duty == 'off' && attend.end != null;
      String _headTitle = '';

      if (proceedingStore.duty == 'on') {
        _headTitle = '勤務中';
        if (isBreak) {
          _headTitle = '休憩中';
        }
      } else {
        if (isResult) {
          _headTitle = DateFormat('yyyy/M/d (E)').format(attend.start!);
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
            if (isRecord) timeRow(context, 'start'),
            if (isResult) timeRow(context, 'end'),
            if (!isRecord && proceedingStore.duty == 'off')
              Text('業務開始時に右下のボタンを押してください'),
            if (isRecord || isResult)
              Expanded(
                  child: ListView.builder(
                      itemCount: attend.breaks.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isResult && index == 0)
                              Text(
                                  '総休憩時間\n' + totalBreaks(attend.breaks, true)),
                            if (attend.breaks.length != 0)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('休憩' + (index + 1).toString()),
                                  ElevatedButton(
                                    child: Text(
                                      '削除',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1,
                                      ),
                                    ),
                                    onPressed: () {
                                      workLogState.breakDelete(index);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 26),
                                    ),
                                  )
                                ],
                              ),
                              timeRow(context, 'end', index),
                            if (isResult && index == attend.breaks.length - 1)
                              ElevatedButton(
                                child: Text(
                                  '休憩記録を追加',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1,
                                  ),
                                ),
                                onPressed: () {
                                  DatePicker.showDateTimePicker(context,
                                      currentTime: attend.start,
                                      locale: LocaleType.jp,
                                      minTime: workLogState.attend.start,
                                      maxTime: workLogState.attend.end,
                                      onConfirm: (startDate) async {
                                    workLogState.editBreakTime(
                                        'start', startDate, null);
                                    await DatePicker.showDateTimePicker(context,
                                        currentTime: attend.breaks.last.start,
                                        locale: LocaleType.jp,
                                        minTime: workLogState
                                            .attend.breaks.last.start,
                                        maxTime: workLogState.attend.end,
                                        onConfirm: (endDate) {
                                      final targetIndex = attend.breaks
                                          .indexWhere((breakInfo) =>
                                              breakInfo.end == null);
                                      workLogState.editBreakTime(
                                          'end', endDate, targetIndex);
                                    }, onCancel: () {
                                      workLogState.addBreakCancel();
                                    });
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 26),
                                ),
                              ),
                          ],
                        );
                      }))
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
                  workLogState.addStartTime();
                } else if (isResult) {
                  workLogState.reset();
                } else {
                  proceedingStore.setDuty('off');
                  workLogState.addEndTime();
                  if (isBreak) {
                    workLogState.addBreakEndTime();
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
                      workLogState.addBreakEndTime();
                    } else {
                      workLogState.addBreakStartTime();
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

  Widget timeRow(BuildContext context, String target, [int? index = null]) {
    String label = target == 'start' ? '開始時刻' : '終了時刻';
    final DateTime? targetDate;
    final bool isBreaks = index == null ? false : true;
    final workLogState =
        Provider.of<WorkLogStateNotifier>(context, listen: false);
    DateTime? maxTime = workLogState.attend.end;
    DateTime? minTime = workLogState.attend.start;
    if (!isBreaks) {
      if (target == 'start') {
        targetDate = workLogState.attend.start!;
        minTime = null;
      } else {
        targetDate = workLogState.attend.end!;
        maxTime = null;
      }
    } else {
      targetDate = target == 'start'
          ? workLogState.attend.breaks[index].start
          : workLogState.attend.breaks[index].end;
    }
    final outputDate = dateFormat(targetDate!);
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
            DatePicker.showDateTimePicker(context,
                currentTime: targetDate,
                locale: LocaleType.jp,
                maxTime: maxTime,
                minTime: minTime, onConfirm: (date) {
              !isBreaks
                  ? workLogState.editTime(target, date)
                  : workLogState.editBreakTime(target, date, index);
            });
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 26),
          ),
        )
      ],
    );
  }

  totalBreaks(List<Breaks> breakLog, [bool toString = false]) {
    var totalDuration;

    breakLog.asMap().forEach((index, breakInfo) {
      final DateTime start = breakInfo.start;
      final DateTime? end = breakInfo.end;
      if (end != null) {
        final duration = end.difference(start);
        if (index == 0) {
          totalDuration = duration;
        } else {
          totalDuration += duration;
        }
      }
    });

    if (toString) {
      return totalDuration.toString().split('.').first.padLeft(8, "0");
    }
    return totalDuration;
  }

  String totalDuty(WorkLogs workLog) {
    final DateTime? start = workLog.start;
    final DateTime? end = workLog.end;
    final List<Breaks> breaks = workLog.breaks;
    var totalDuration = end!.difference(start!);

    if (breaks.isNotEmpty &&
        breaks.every((breaksInfo) => breaksInfo.end != null)) {
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
