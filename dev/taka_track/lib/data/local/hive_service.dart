import 'package:hive_flutter/hive_flutter.dart';
import '../models/taka_design.dart';
import '../models/taka_activity.dart';
import '../../core/constants/app_constants.dart';

class HiveService {
  late Box<TakaDesign> _designsBox;
  late Box<TakaActivity> _activitiesBox;
  late Box<dynamic> _syncQueueBox;

  Future<void> init() async {
    _designsBox = await Hive.openBox<TakaDesign>(AppConstants.designsBox);
    _activitiesBox =
        await Hive.openBox<TakaActivity>(AppConstants.activitiesBox);
    _syncQueueBox = await Hive.openBox<dynamic>(AppConstants.syncQueueBox);
  }

  // ──────────────────────────────────────────────
  // Design CRUD
  // ──────────────────────────────────────────────

  Future<void> saveDesign(TakaDesign design) async {
    await _designsBox.put(design.id, design);
  }

  Future<void> saveAllDesigns(List<TakaDesign> designs) async {
    final map = {for (final d in designs) d.id: d};
    await _designsBox.putAll(map);
  }

  TakaDesign? getDesign(String id) => _designsBox.get(id);

  List<TakaDesign> getAllDesigns() => _designsBox.values.toList();

  Future<void> deleteDesign(String id) async {
    await _designsBox.delete(id);
  }

  Future<void> updateTakaCount(String designId, int newCount) async {
    final design = _designsBox.get(designId);
    if (design != null) {
      design.currentTakaCount = newCount;
      design.updatedAt = DateTime.now();
      await design.save();
    }
  }

  // ──────────────────────────────────────────────
  // Activity CRUD
  // ──────────────────────────────────────────────

  Future<void> saveActivity(TakaActivity activity) async {
    await _activitiesBox.put(activity.id, activity);
  }

  Future<void> saveAllActivities(List<TakaActivity> activities) async {
    final map = {for (final a in activities) a.id: a};
    await _activitiesBox.putAll(map);
  }

  List<TakaActivity> getRecentActivities({int limit = 20}) {
    final all = _activitiesBox.values.toList();
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(limit).toList();
  }

  // ──────────────────────────────────────────────
  // Sync queue helpers
  // ──────────────────────────────────────────────

  Box<dynamic> get syncQueueBox => _syncQueueBox;

  // ──────────────────────────────────────────────
  // Stats helpers
  // ──────────────────────────────────────────────

  int getTotalTakas() {
    int total = 0;
    for (final d in _designsBox.values) {
      total += d.currentTakaCount;
    }
    return total;
  }

  int getInwardToday() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _activitiesBox.values
        .where((a) =>
            a.isInward && a.timestamp.isAfter(todayStart))
        .fold(0, (sum, a) => sum + a.delta.abs());
  }

  int getOutwardToday() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _activitiesBox.values
        .where((a) =>
            !a.isInward && a.timestamp.isAfter(todayStart))
        .fold(0, (sum, a) => sum + a.delta.abs());
  }

  int getLowStockCount(int threshold) {
    return _designsBox.values
        .where((d) => d.currentTakaCount <= threshold)
        .length;
  }

  Future<void> closeAll() async {
    await _designsBox.close();
    await _activitiesBox.close();
    await _syncQueueBox.close();
  }
}
