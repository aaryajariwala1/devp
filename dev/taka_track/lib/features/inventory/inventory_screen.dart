import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/taka_design.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../widgets/design_card.dart';
import '../widgets/taka_adjust_sheet.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const LoadInventory());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: BlocBuilder<InventoryBloc, InventoryState>(
                builder: (context, state) {
                  if (state is InventoryLoading) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.mint),
                    );
                  }
                  if (state is InventoryError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: AppColors.coral),
                          const SizedBox(height: 12),
                          Text(state.message,
                              style: const TextStyle(color: AppColors.muted)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context
                                .read<InventoryBloc>()
                                .add(const LoadInventory()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is InventoryLoaded) {
                    return _buildContent(state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDesignDialog(context),
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Design',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _searchExpanded
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  color: AppColors.muted,
                ),
                onPressed: () {
                  setState(() {
                    _searchExpanded = !_searchExpanded;
                    if (!_searchExpanded) {
                      _searchController.clear();
                      context
                          .read<InventoryBloc>()
                          .add(const SearchDesign(''));
                    }
                  });
                },
              ),
            ],
          ),
          // Search bar (animated expand)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Search designs...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.muted, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppColors.muted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<InventoryBloc>()
                                .add(const SearchDesign(''));
                          },
                        )
                      : null,
                ),
                onChanged: (q) => context
                    .read<InventoryBloc>()
                    .add(SearchDesign(q)),
              ),
            ),
            crossFadeState: _searchExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          // Filter chips
          BlocBuilder<InventoryBloc, InventoryState>(
            builder: (context, state) {
              final lowStockOnly = state is InventoryLoaded
                  ? state.lowStockOnly
                  : false;
              return Row(
                children: [
                  FilterChip(
                    label: const Text('Low Stock Only'),
                    selected: lowStockOnly,
                    onSelected: (val) => context
                        .read<InventoryBloc>()
                        .add(FilterLowStock(val)),
                    selectedColor: AppColors.amber.withOpacity(0.2),
                    checkmarkColor: AppColors.amber,
                    labelStyle: TextStyle(
                      color: lowStockOnly ? AppColors.amber : AppColors.muted,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: lowStockOnly
                          ? AppColors.amber
                          : AppColors.divider,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(InventoryLoaded state) {
    if (state.filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_rounded,
                size: 64, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'No designs match "${state.searchQuery}"'
                  : state.lowStockOnly
                      ? 'No low stock designs!'
                      : 'No designs yet',
              style: const TextStyle(color: AppColors.muted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.mint,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        context.read<InventoryBloc>().add(const RefreshInventory());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.82,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.filtered.length,
        itemBuilder: (context, index) {
          final design = state.filtered[index];
          return DesignCard(
            design: design,
            onTap: () => TakaAdjustSheet.show(context, design),
            onQuickAdd: () => context.read<InventoryBloc>().add(
                  AdjustTakas(designId: design.id, delta: 1),
                ),
            onQuickRemove: () => context.read<InventoryBloc>().add(
                  AdjustTakas(designId: design.id, delta: -1),
                ),
          );
        },
      ),
    );
  }

  void _showAddDesignDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Add Design feature coming soon'),
          behavior: SnackBarBehavior.floating),
    );
  }
}
