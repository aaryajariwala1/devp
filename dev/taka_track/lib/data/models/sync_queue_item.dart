class SyncQueueItem {
  final String id;
  final String method; // POST, PUT, DELETE
  final String endpoint;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;

  SyncQueueItem({
    required this.id,
    required this.method,
    required this.endpoint,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'endpoint': endpoint,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'] as String,
        method: json['method'] as String,
        endpoint: json['endpoint'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}
