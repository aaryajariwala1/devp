import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/taka_activity.dart';
import '../../../data/remote/inventory_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final InventoryRepository _repository;

  DashboardBloc({required InventoryRepository repository})
      : _repository = repository,
        super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshDashboard>(_onRefresh);
    on<ActivityReceived>(_onActivityReceived);
  }

  Future<void> _onLoad(
      LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(const DashboardLoading());

    // 1. Emit cached data immediately
    try {
      final cachedStats = _repository.getCachedDashboardStats();
      final cachedActivities = _repository.getCachedActivities();
      emit(DashboardLoaded(
          stats: cachedStats, recentActivities: cachedActivities));
    } catch (_) {
      // Cached data unavailable, keep loading
    }

    // 2. Fetch fresh data from API in background
    await _fetchFreshData(emit);
  }

  Future<void> _onRefresh(
      RefreshDashboard event, Emitter<DashboardState> emit) async {
    await _fetchFreshData(emit);
  }

  Future<void> _fetchFreshData(Emitter<DashboardState> emit) async {
    try {
      final results = await Future.wait([
        _repository.fetchDashboardStats(),
        _repository.fetchRecentActivities(),
      ]);

      final stats = results[0] as DashboardStats;
      final activities = results[1] as List<TakaActivity>;

      emit(DashboardLoaded(stats: stats, recentActivities: activities));
    } catch (e) {
      // If we already have cached data loaded, don't replace with error
      if (state is DashboardLoaded) return;
      emit(DashboardError(e.toString()));
    }
  }

  void _onActivityReceived(
      ActivityReceived event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      final current = state as DashboardLoaded;
      final updatedActivities = [
        event.activity,
        ...current.recentActivities,
      ].take(20).toList();

      // Update stats based on new activity
      final inwardDelta = event.activity.isInward ? event.activity.delta : 0;
      final outwardDelta = event.activity.isInward ? 0 : event.activity.delta.abs();

      final updatedStats = DashboardStats(
        totalTakas: current.stats.totalTakas + (event.activity.isInward
            ? event.activity.delta
            : -event.activity.delta.abs()),
        inwardToday: current.stats.inwardToday + inwardDelta,
        outwardToday: current.stats.outwardToday + outwardDelta,
        lowStockCount: current.stats.lowStockCount,
      );

      emit(current.copyWith(
        stats: updatedStats,
        recentActivities: updatedActivities,
      ));
    }
  }
}
