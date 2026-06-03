import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/taka_design.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';

class TakaAdjustSheet extends StatefulWidget {
  final TakaDesign design;

  const TakaAdjustSheet({super.key, required this.design});

  static Future<void> show(BuildContext context, TakaDesign design) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<InventoryBloc>(),
        child: TakaAdjustSheet(design: design),
      ),
    );
  }

  @override
  State<TakaAdjustSheet> createState() => _TakaAdjustSheetState();
}

class _TakaAdjustSheetState extends State<TakaAdjustSheet> {
  int _quantity = 1;
  String _type = 'INWARD';
  final TextEditingController _noteController = TextEditingController();

  int get _effectiveDelta => _type == 'INWARD' ? _quantity : -_quantity;
  int get _previewCount =>
      (widget.design.currentTakaCount + _effectiveDelta).clamp(0, 9999);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Design name
              Text(
                widget.design.designName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Current: ',
                      style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  Text(
                    '${widget.design.currentTakaCount} takas',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const Text(' → ', style: TextStyle(color: AppColors.muted)),
                  Text(
                    '$_previewCount takas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _type == 'INWARD' ? AppColors.mint : AppColors.coral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // INWARD/OUTWARD toggle
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'INWARD',
                      isSelected: _type == 'INWARD',
                      selectedColor: AppColors.mint,
                      onTap: () => setState(() => _type = 'INWARD'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      label: 'OUTWARD',
                      isSelected: _type == 'OUTWARD',
                      selectedColor: AppColors.coral,
                      onTap: () => setState(() => _type = 'OUTWARD'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Quantity stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepBtn(
                    icon: Icons.remove,
                    onTap: () =>
                        setState(() => _quantity = (_quantity - 1).clamp(1, 9999)),
                  ),
                  const SizedBox(width: 32),
                  Column(
                    children: [
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          height: 1,
                        ),
                      ),
                      const Text(
                        'TAKAS',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  _StepBtn(
                    icon: Icons.add,
                    onTap: () =>
                        setState(() => _quantity = (_quantity + 1).clamp(1, 9999)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quick select
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [5, 10, 20, 50].map((n) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _quantity = n),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _quantity == n
                              ? AppColors.mint.withOpacity(0.2)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _quantity == n
                                ? AppColors.mint
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          '+$n',
                          style: TextStyle(
                            fontSize: 12,
                            color: _quantity == n
                                ? AppColors.mint
                                : AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Note field
              TextField(
                controller: _noteController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  hintText: 'Note (optional)',
                  prefixIcon: Icon(Icons.edit_note_rounded,
                      color: AppColors.muted, size: 20),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 20),
              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _type == 'INWARD' ? AppColors.mint : AppColors.coral,
                    foregroundColor: AppColors.background,
                  ),
                  child: Text(
                    _type == 'INWARD'
                        ? 'Add $_quantity Takas'
                        : 'Remove $_quantity Takas',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    context.read<InventoryBloc>().add(AdjustTakas(
          designId: widget.design.id,
          delta: _effectiveDelta,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        ));
    Navigator.of(context).pop();
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: isSelected ? selectedColor : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceLight,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, color: AppColors.white, size: 24),
      ),
    );
  }
}
