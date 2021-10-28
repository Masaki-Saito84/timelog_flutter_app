import 'package:json_annotation/json_annotation.dart';
part 'breaks.g.dart';

@JsonSerializable(explicitToJson: true)
class Breaks {
  DateTime start;
  DateTime? end;
  Breaks(this.start, this.end);

  factory Breaks.fromJson(Map<String, dynamic> json) => _$BreaksFromJson(json);

  Map<String, dynamic> toJson() => _$BreaksToJson(this);
}
