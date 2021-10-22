// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breaks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Breaks _$BreaksFromJson(Map<String, dynamic> json) => Breaks(
      DateTime.parse(json['start'] as String),
      DateTime.parse(json['end'] as String),
    );

Map<String, dynamic> _$BreaksToJson(Breaks instance) => <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
    };
