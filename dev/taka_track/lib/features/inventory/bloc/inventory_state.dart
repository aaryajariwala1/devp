import 'package:equatable/equatable.dart';
import '../../../data/models/taka_design.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  final List<TakaDesign> designs;
  final List<TakaDesign> filtered;
  final String searchQuery;
  final bool lowStockOnly;

  const InventoryLoaded({
    required this.designs,
    required this.filtered,
    this.searchQuery = '',
    this.lowStockOnly = false,
  });

  InventoryLoaded copyWith({
    List<TakaDesign>? designs,
    List<TakaDesign>? filtered,
    String? searchQuery,
    bool? lowStockOnly,
  }) {
    return InventoryLoaded(
      designs: designs ?? this.designs,
      filtered: filtered ?? this.filtered,
      searchQuery: searchQuery ?? this.searchQuery,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
    );
  }

  @override
  List<Object?> get props => [designs, filtered, searchQuery, lowStockOnly];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}
