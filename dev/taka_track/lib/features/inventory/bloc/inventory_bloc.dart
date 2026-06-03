import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/taka_design.dart';
import '../../../data/remote/inventory_repository.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository _repository;

  InventoryBloc({required InventoryRepository repository})
      : _repository = repository,
        super(const InventoryInitial()) {
    on<LoadInventory>(_onLoad);
    on<RefreshInventory>(_onRefresh);
    on<AdjustTakas>(_onAdjust);
    on<SearchDesign>(_onSearch);
    on<FilterLowStock>(_onFilter);
  }

  Future<void> _onLoad(
      LoadInventory event, Emitter<InventoryState> emit) async {
    emit(const InventoryLoading());

    // Emit cached data first
    final cached = _repository.getCachedDesigns();
    if (cached.isNotEmpty) {
      emit(InventoryLoaded(
        designs: cached,
        filtered: cached,
      ));
    }

    // Fetch fresh from API
    try {
      final designs = await _repository.fetchDesigns();
      emit(InventoryLoaded(
        designs: designs,
        filtered: designs,
      ));
    } catch (e) {
      if (state is! InventoryLoaded) {
        emit(InventoryError(e.toString()));
      }
    }
  }

  Future<void> _onRefresh(
      RefreshInventory event, Emitter<InventoryState> emit) async {
    try {
      final designs = await _repository.fetchDesigns();
      if (state is InventoryLoaded) {
        final current = state as InventoryLoaded;
        final filtered =
            _applyFilters(designs, current.searchQuery, current.lowStockOnly);
        emit(current.copyWith(designs: designs, filtered: filtered));
      } else {
        emit(InventoryLoaded(designs: designs, filtered: designs));
      }
    } catch (e) {
      // Keep current state on refresh failure
    }
  }

  Future<void> _onAdjust(
      AdjustTakas event, Emitter<InventoryState> emit) async {
    if (state is! InventoryLoaded) return;
    final current = state as InventoryLoaded;

    // Optimistic update
    final updatedDesigns = current.designs.map((d) {
      if (d.id == event.designId) {
        return d.copyWith(
          currentTakaCount:
              (d.currentTakaCount + event.delta).clamp(0, 9999),
          updatedAt: DateTime.now(),
        );
      }
      return d;
    }).toList();

    final updatedFiltered = _applyFilters(
        updatedDesigns, current.searchQuery, current.lowStockOnly);
    emit(current.copyWith(
        designs: updatedDesigns, filtered: updatedFiltered));

    // API call (optimistic already done)
    try {
      await _repository.adjustInventory(
          event.designId, event.delta, event.note);
    } catch (_) {
      // Already optimistically updated & added to sync queue in repository
    }
  }

  void _onSearch(SearchDesign event, Emitter<InventoryState> emit) {
    if (state is! InventoryLoaded) return;
    final current = state as InventoryLoaded;
    final filtered =
        _applyFilters(current.designs, event.query, current.lowStockOnly);
    emit(current.copyWith(filtered: filtered, searchQuery: event.query));
  }

  void _onFilter(FilterLowStock event, Emitter<InventoryState> emit) {
    if (state is! InventoryLoaded) return;
    final current = state as InventoryLoaded;
    final filtered =
        _applyFilters(current.designs, current.searchQuery, event.enabled);
    emit(current.copyWith(filtered: filtered, lowStockOnly: event.enabled));
  }

  List<TakaDesign> _applyFilters(
      List<TakaDesign> designs, String query, bool lowStockOnly) {
    var result = designs;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result
          .where((d) => d.designName.toLowerCase().contains(q))
          .toList();
    }
    if (lowStockOnly) {
      result = result.where((d) => d.isLowStock).toList();
    }
    return result;
  }
}
