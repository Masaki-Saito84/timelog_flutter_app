// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_logs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkLogs _$WorkLogsFromJson(Map<String, dynamic> json) => WorkLogs(
      json['start'] == null ? null : DateTime.parse(json['start'] as String),
      json['end'] == null ? null : DateTime.parse(json['end'] as String),
      (json['breaks'] as List<dynamic>)
          .map((e) => Breaks.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkLogsToJson(WorkLogs instance) => <String, dynamic>{
      'start': instance.start?.toIso8601String(),
      'end': instance.end?.toIso8601String(),
      'breaks': instance.breaks.map((e) => e.toJson()).toList(),
    };
