import 'package:hive/hive.dart';
part 'taka_activity.g.dart';

@HiveType(typeId: 1)
class TakaActivity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String designId;

  @HiveField(2)
  final String designName;

  @HiveField(3)
  final int delta; // positive=inward, negative=outward

  @HiveField(4)
  final String type; // 'INWARD' | 'OUTWARD'

  @HiveField(5)
  final String? note;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final String? thumbnailUrl;

  TakaActivity({
    required this.id,
    required this.designId,
    required this.designName,
    required this.delta,
    required this.type,
    this.note,
    required this.timestamp,
    this.thumbnailUrl,
  });

  bool get isInward => type == 'INWARD';

  factory TakaActivity.fromJson(Map<String, dynamic> json) => TakaActivity(
        id: json['id'] as String,
        designId: json['design_id'] as String,
        designName: json['design_name'] as String? ?? 'Unknown',
        delta: json['quantity_changed'] as int,
        type: json['type'] as String,
        note: json['note'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        thumbnailUrl: json['thumbnail_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'design_id': designId,
        'design_name': designName,
        'quantity_changed': delta,
        'type': type,
        'note': note,
        'timestamp': timestamp.toIso8601String(),
        'thumbnail_url': thumbnailUrl,
      };
}
