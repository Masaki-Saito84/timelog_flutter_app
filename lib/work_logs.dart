import 'package:json_annotation/json_annotation.dart';
import 'breaks.dart';

part 'work_logs.g.dart';

@JsonSerializable(explicitToJson: true)
class WorkLogs {
  String? start;
  String? end;
  List<Breaks>? breaks;
  WorkLogs(this.start, this.end, this.breaks);

  factory WorkLogs.fromJson(Map<String, dynamic> json) => _$WorkLogsFromJson(json);

  Map<String, dynamic> toJson() => _$WorkLogsToJson(this);

}
