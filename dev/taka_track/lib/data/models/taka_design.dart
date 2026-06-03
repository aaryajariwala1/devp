import 'package:hive/hive.dart';
part 'taka_design.g.dart';

@HiveType(typeId: 0)
class TakaDesign extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String designName;

  @HiveField(2)
  int currentTakaCount;

  @HiveField(3)
  final int lowStockThreshold;

  @HiveField(4)
  String? thumbnailUrl;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  TakaDesign({
    required this.id,
    required this.designName,
    required this.currentTakaCount,
    this.lowStockThreshold = 5,
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => currentTakaCount <= lowStockThreshold;

  factory TakaDesign.fromJson(Map<String, dynamic> json) => TakaDesign(
        id: json['design_id'] as String,
        designName: json['design_name'] as String,
        currentTakaCount: json['current_taka_count'] as int,
        lowStockThreshold: json['low_stock_threshold'] as int? ?? 5,
        thumbnailUrl: json['thumbnail_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(
            json['updated_at'] as String? ?? json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'design_id': id,
        'design_name': designName,
        'current_taka_count': currentTakaCount,
        'low_stock_threshold': lowStockThreshold,
        'thumbnail_url': thumbnailUrl,
      };

  TakaDesign copyWith({
    String? id,
    String? designName,
    int? currentTakaCount,
    int? lowStockThreshold,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TakaDesign(
      id: id ?? this.id,
      designName: designName ?? this.designName,
      currentTakaCount: currentTakaCount ?? this.currentTakaCount,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
