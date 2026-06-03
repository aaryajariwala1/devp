import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../local/hive_service.dart';
import '../local/sync_queue.dart';
import '../models/taka_activity.dart';
import '../models/taka_design.dart';
import '../models/sync_queue_item.dart';
import '../remote/api_client.dart';
import '../../core/constants/app_constants.dart';

class DashboardStats {
  final int totalTakas;
  final int inwardToday;
  final int outwardToday;
  final int lowStockCount;

  const DashboardStats({
    required this.totalTakas,
    required this.inwardToday,
    required this.outwardToday,
    required this.lowStockCount,
  });

  factory DashboardStats.empty() => const DashboardStats(
        totalTakas: 0,
        inwardToday: 0,
        outwardToday: 0,
        lowStockCount: 0,
      );

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalTakas: json['total_takas'] as int? ?? 0,
        inwardToday: json['inward_today'] as int? ?? 0,
        outwardToday: json['outward_today'] as int? ?? 0,
        lowStockCount: json['low_stock_count'] as int? ?? 0,
      );
}

class ScanResult {
  final bool matched;
  final String? designId;
  final String? designName;
  final double confidence;
  final int? takaCount;
  final bool isNewDesign;

  const ScanResult({
    required this.matched,
    this.designId,
    this.designName,
    required this.confidence,
    this.takaCount,
    this.isNewDesign = false,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        matched: json['matched'] as bool? ?? false,
        designId: json['design_id'] as String?,
        designName: json['design_name'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        takaCount: json['taka_count'] as int?,
        isNewDesign: json['is_new_design'] as bool? ?? false,
      );

  factory ScanResult.noMatch() => const ScanResult(
        matched: false,
        confidence: 0.0,
        isNewDesign: true,
      );
}

class InventoryRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;
  late final SyncQueue _syncQueue;
  final _uuid = const Uuid();

  Dio get _dio => _apiClient.dio;

  InventoryRepository({
    required ApiClient apiClient,
    required HiveService hiveService,
  })  : _apiClient = apiClient,
        _hiveService = hiveService {
    _syncQueue = SyncQueue(hiveService: hiveService);
  }

  // ──────────────────────────────────────────────
  // Dashboard
  // ──────────────────────────────────────────────

  DashboardStats getCachedDashboardStats() {
    return DashboardStats(
      totalTakas: _hiveService.getTotalTakas(),
      inwardToday: _hiveService.getInwardToday(),
      outwardToday: _hiveService.getOutwardToday(),
      lowStockCount:
          _hiveService.getLowStockCount(AppConstants.lowStockThreshold),
    );
  }

  Future<DashboardStats> fetchDashboardStats() async {
    try {
      final response = await _dio.get('/api/dashboard/stats');
      final stats = DashboardStats.fromJson(
          response.data as Map<String, dynamic>);
      return stats;
    } catch (_) {
      return getCachedDashboardStats();
    }
  }

  // ──────────────────────────────────────────────
  // Activities
  // ──────────────────────────────────────────────

  List<TakaActivity> getCachedActivities({int limit = 20}) {
    return _hiveService.getRecentActivities(limit: limit);
  }

  Future<List<TakaActivity>> fetchRecentActivities({int limit = 20}) async {
    try {
      final response =
          await _dio.get('/api/activities', queryParameters: {'limit': limit});
      final list = (response.data as List<dynamic>)
          .map((e) => TakaActivity.fromJson(e as Map<String, dynamic>))
          .toList();
      await _hiveService.saveAllActivities(list);
      return list;
    } catch (_) {
      return _hiveService.getRecentActivities(limit: limit);
    }
  }

  // ──────────────────────────────────────────────
  // Designs
  // ──────────────────────────────────────────────

  List<TakaDesign> getCachedDesigns({bool lowStockOnly = false}) {
    final all = _hiveService.getAllDesigns();
    if (lowStockOnly) {
      return all
          .where((d) => d.currentTakaCount <= AppConstants.lowStockThreshold)
          .toList();
    }
    return all;
  }

  Future<List<TakaDesign>> fetchDesigns({bool lowStockOnly = false}) async {
    try {
      final response = await _dio.get(
        '/api/designs',
        queryParameters: lowStockOnly ? {'low_stock_only': true} : null,
      );
      final list = (response.data as List<dynamic>)
          .map((e) => TakaDesign.fromJson(e as Map<String, dynamic>))
          .toList();
      await _hiveService.saveAllDesigns(list);
      return list;
    } catch (_) {
      return _hiveService.getAllDesigns();
    }
  }

  // ──────────────────────────────────────────────
  // Adjust inventory (optimistic)
  // ──────────────────────────────────────────────

  Future<void> adjustInventory(
    String designId,
    int delta,
    String? note,
  ) async {
    // 1. Optimistic local update
    final design = _hiveService.getDesign(designId);
    if (design != null) {
      final newCount = (design.currentTakaCount + delta).clamp(0, 9999);
      await _hiveService.updateTakaCount(designId, newCount);
    }

    // 2. Save activity locally
    final activityId = _uuid.v4();
    final activity = TakaActivity(
      id: activityId,
      designId: designId,
      designName: design?.designName ?? 'Unknown',
      delta: delta,
      type: delta >= 0 ? 'INWARD' : 'OUTWARD',
      note: note,
      timestamp: DateTime.now(),
      thumbnailUrl: design?.thumbnailUrl,
    );
    await _hiveService.saveActivity(activity);

    // 3. Try API
    try {
      await _dio.post(
        '/api/inventory/adjust',
        data: {
          'design_id': designId,
          'delta': delta,
          'note': note,
          'type': delta >= 0 ? 'INWARD' : 'OUTWARD',
        },
      );
    } catch (_) {
      // Add to sync queue for later
      final syncItem = SyncQueueItem(
        id: _uuid.v4(),
        method: 'POST',
        endpoint: '/api/inventory/adjust',
        payload: {
          'design_id': designId,
          'delta': delta,
          'note': note,
          'type': delta >= 0 ? 'INWARD' : 'OUTWARD',
        },
        createdAt: DateTime.now(),
      );
      await _syncQueue.addToQueue(syncItem);
    }
  }

  // ──────────────────────────────────────────────
  // Scanner
  // ──────────────────────────────────────────────

  Future<ScanResult> scanDesign(Uint8List imageBytes) async {
    try {
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: 'scan.jpg'),
      });
      final response = await _dio.post('/api/scan', data: formData);
      return ScanResult.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return ScanResult.noMatch();
    }
  }

  Future<bool> registerDesignEmbedding(
      String designId, Uint8List imageBytes) async {
    try {
      final formData = FormData.fromMap({
        'design_id': designId,
        'image':
            MultipartFile.fromBytes(imageBytes, filename: 'embedding.jpg'),
      });
      final response = await _dio.post('/api/designs/register', data: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Sync
  // ──────────────────────────────────────────────

  Future<void> processSyncQueue() async {
    await _syncQueue.processQueue(_dio);
  }

  int getPendingSyncCount() => _syncQueue.getPendingCount();
}
