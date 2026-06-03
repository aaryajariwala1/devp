import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/taka_design.dart';
import 'data/models/taka_activity.dart';
import 'data/local/hive_service.dart';
import 'data/remote/api_client.dart';
import 'data/remote/inventory_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TakaDesignAdapter());
  Hive.registerAdapter(TakaActivityAdapter());

  // Initialize services
  final hiveService = HiveService();
  await hiveService.init();

  final apiClient = ApiClient();

  final repository = InventoryRepository(
    apiClient: apiClient,
    hiveService: hiveService,
  );

  runApp(TakaTrackApp(repository: repository));
}
