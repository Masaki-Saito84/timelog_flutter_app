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
      bool isBreak = onDutyState.attend!.breaks.any((acquiredBreak) => acquiredBreak.start != '' && acquiredBreak.end == '');
      bool isRecord = onDutyState.attend.start != '';
      bool isResult = proceedingStore.duty == 'off' && onDutyState.attend!.end != '';
      String _headTitle = '';

      return Scaffold(
        appBar: AppBar(
          title: Text(_headTitle),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(proceedingStore.duty == 'on') Text('勤務時間'),
            if(isRecord) timeRow('開始時刻', onDutyState.attend!.start.toString()),
            if(isResult) timeRow('終了時刻', onDutyState.attend!.end.toString()),
            if(!isRecord && proceedingStore.duty == 'off') Text('業務開始時に右下のボタンを押してください'),
            if(isRecord || isResult) Expanded(
              child: ListView.builder(
                itemCount: onDutyState.attend!.breaks.length,
                itemBuilder: (BuildContext context, int index) {
                  bool isInitBreak = onDutyState.attend!.breaks[index].start.toString() == '' && onDutyState.attend!.breaks[index].end.toString() == '';
                  if (!isInitBreak) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if(isBreak) Text('休憩中'),
                        Text('休憩' + (index + 1).toString()),
                        timeRow('開始時刻', onDutyState.attend!.breaks[index].start.toString()),
                        if(onDutyState.attend!.breaks[index].end.toString() != '') timeRow('終了時刻', onDutyState.attend!.breaks[index].end.toString()),
                      ],
                    );
                  } else if(isResult) {
                    return ElevatedButton(
                      child: Text(
                        '休憩記録を追加',
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
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }
              )
            ),
          ],
        ),
        floatingActionButton: Container(
          child: Column(
            verticalDirection: VerticalDirection.up,
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: () {
                  if(!isRecord) {
                    proceedingStore.setDuty('on');
                    onDutyState.addStartTime();
                  } else if(isResult) {
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
                  if(onDutyState.attend!.start == '') {
                    return Icon(Icons.play_arrow);
                  } else if(onDutyState.attend!.start != '' && onDutyState.attend!.end != '') {
                    return Icon(Icons.restart_alt);
                  } else {
                    return Icon(Icons.stop);
                  }
                }) (),
              ),
              if(proceedingStore.duty == 'on') Container(
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
          )
        ),
      );
    });
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
  }
  void allTimeClear() {
    swatch.reset();
  }
}
