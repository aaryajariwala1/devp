import '../../../data/models/taka_activity.dart';

abstract class DashboardEvent {
  const DashboardEvent();
}

class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

class RefreshDashboard extends DashboardEvent {
  const RefreshDashboard();
}

class ActivityReceived extends DashboardEvent {
  final TakaActivity activity;
  const ActivityReceived(this.activity);
}
