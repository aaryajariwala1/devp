class AppConstants {
  AppConstants._();

  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String wsUrl = 'ws://10.0.2.2:8000/ws/inventory';
  static const int lowStockThreshold = 5;
  static const String designsBox = 'designs_box';
  static const String activitiesBox = 'activities_box';
  static const String syncQueueBox = 'sync_queue_box';
  static const int maxImageDimension = 500;
  static const int imageQuality = 82;
}
