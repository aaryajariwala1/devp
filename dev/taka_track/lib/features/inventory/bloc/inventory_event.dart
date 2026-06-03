import '../../../data/models/taka_design.dart';

abstract class InventoryEvent {
  const InventoryEvent();
}

class LoadInventory extends InventoryEvent {
  const LoadInventory();
}

class RefreshInventory extends InventoryEvent {
  const RefreshInventory();
}

class AdjustTakas extends InventoryEvent {
  final String designId;
  final int delta;
  final String? note;

  const AdjustTakas({
    required this.designId,
    required this.delta,
    this.note,
  });
}

class SearchDesign extends InventoryEvent {
  final String query;
  const SearchDesign(this.query);
}

class FilterLowStock extends InventoryEvent {
  final bool enabled;
  const FilterLowStock(this.enabled);
}
