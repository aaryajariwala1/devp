import 'package:equatable/equatable.dart';
import '../../../data/models/taka_activity.dart';
import '../../../data/remote/inventory_repository.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final List<TakaActivity> recentActivities;

  const DashboardLoaded({
    required this.stats,
    required this.recentActivities,
  });

  DashboardLoaded copyWith({
    DashboardStats? stats,
    List<TakaActivity>? recentActivities,
  }) {
    return DashboardLoaded(
      stats: stats ?? this.stats,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }

  @override
  List<Object?> get props => [stats, recentActivities];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
