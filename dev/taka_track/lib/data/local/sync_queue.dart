import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/sync_queue_item.dart';
import 'hive_service.dart';

class SyncQueue {
  final HiveService _hiveService;
  static const int _maxRetries = 3;

  SyncQueue({required HiveService hiveService}) : _hiveService = hiveService;

  Future<void> addToQueue(SyncQueueItem item) async {
    final box = _hiveService.syncQueueBox;
    await box.put(item.id, jsonEncode(item.toJson()));
  }

  int getPendingCount() {
    return _hiveService.syncQueueBox.length;
  }

  Future<void> processQueue(Dio dio) async {
    final box = _hiveService.syncQueueBox;
    if (box.isEmpty) return;

    final keysToDelete = <dynamic>[];
    final itemsToUpdate = <String, SyncQueueItem>{};

    for (final key in box.keys.toList()) {
      final raw = box.get(key);
      if (raw == null) continue;

      SyncQueueItem item;
      try {
        item = SyncQueueItem.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
      } catch (_) {
        keysToDelete.add(key);
        continue;
      }

      if (item.retryCount >= _maxRetries) {
        keysToDelete.add(key);
        continue;
      }

      try {
        Response response;
        switch (item.method.toUpperCase()) {
          case 'POST':
            response = await dio.post(item.endpoint, data: item.payload);
            break;
          case 'PUT':
            response = await dio.put(item.endpoint, data: item.payload);
            break;
          case 'DELETE':
            response = await dio.delete(item.endpoint, data: item.payload);
            break;
          default:
            keysToDelete.add(key);
            continue;
        }

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          keysToDelete.add(key);
        } else {
          item.retryCount++;
          itemsToUpdate[item.id] = item;
        }
      } on DioException catch (_) {
        final backoffSeconds = _backoff(item.retryCount);
        await Future.delayed(Duration(seconds: backoffSeconds));
        item.retryCount++;
        itemsToUpdate[item.id] = item;
      } catch (_) {
        item.retryCount++;
        itemsToUpdate[item.id] = item;
      }
    }

    // Apply updates
    for (final entry in itemsToUpdate.entries) {
      await box.put(entry.key, jsonEncode(entry.value.toJson()));
    }

    // Delete completed/exhausted items
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  Future<void> clearCompleted() async {
    final box = _hiveService.syncQueueBox;
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw == null) {
        keysToDelete.add(key);
        continue;
      }
      try {
        final item = SyncQueueItem.fromJson(
            jsonDecode(raw as String) as Map<String, dynamic>);
        if (item.retryCount >= _maxRetries) {
          keysToDelete.add(key);
        }
      } catch (_) {
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  int _backoff(int retryCount) => (1 << retryCount).clamp(1, 8); // 2^retry seconds
}
