import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../controllers/fitgrid_plus_controller.dart';
import '../models/fitgrid_plus_editing_options.dart';
import '../models/fitgrid_plus_view_mode.dart';

/// Context menu builder and presenter for cell/row right-clicks, long-presses, and card popups.
class FitGridPlusContextMenu {
  const FitGridPlusContextMenu._();

  /// Builds a list of [PopupMenuEntry] elements tailored for the selected record and cell.
  static List<PopupMenuEntry<void>> buildMenuItems({
    required BuildContext context,
    required FitGridPlusController controller,
    required Map<String, dynamic> row,
    required int rowIndex,
    String? columnField,
    dynamic cellValue,
    List<PopupMenuEntry<void>>? defaultItems,
  }) {
    final config = controller.contextMenuConfig;
    if (!config.enabled) {
      return defaultItems ?? const <PopupMenuEntry<void>>[];
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = <PopupMenuEntry<void>>[];

    PopupMenuItem<void> createItem({
      required String label,
      required IconData icon,
      required VoidCallback onTap,
      bool isDestructive = false,
    }) {
      final itemColor = isDestructive
          ? colorScheme.error
          : colorScheme.onSurface;

      return PopupMenuItem<void>(
        onTap: () {
          onTap();
          config.onActionExecuted?.call(label, row);
        },
        height: 38,
        child: Row(
          children: [
            Icon(icon, size: 18, color: itemColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: itemColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // 1. Filter Similar Records
    if (config.enableFilterSimilar &&
        columnField != null &&
        cellValue != null &&
        cellValue.toString().trim().isNotEmpty) {
      final valStr = cellValue.toString();
      final preview = valStr.length > 16
          ? '${valStr.substring(0, 14)}…'
          : valStr;
      items.add(
        createItem(
          label: 'Filter Similar: $preview',
          icon: Icons.filter_alt_outlined,
          onTap: () =>
              controller.filterSimilar(field: columnField, value: cellValue),
        ),
      );
    }

    // 2. Clipboard Actions
    if (config.enableClipboardActions) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider(height: 8));
      if (cellValue != null) {
        items.add(
          createItem(
            label: 'Copy Cell Value',
            icon: Icons.copy_outlined,
            onTap: () {
              Clipboard.setData(ClipboardData(text: cellValue.toString()));
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(
                  content: Text('Copied "$cellValue" to clipboard'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      }
      items.add(
        createItem(
          label: 'Copy Row (JSON)',
          icon: Icons.data_object_rounded,
          onTap: () {
            Clipboard.setData(ClipboardData(text: jsonEncode(row)));
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Copied row JSON to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    }

    // 3. Row Editing Actions
    if (!controller.isReadonly &&
        config.enableEditingActions &&
        controller.editingOptions.enabled) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider(height: 8));
      if (controller.editingOptions.allowUpdating) {
        items.add(
          createItem(
            label: 'Edit Row',
            icon: Icons.edit_outlined,
            onTap: () {
              if (controller.editingOptions.mode == FitGridPlusEditMode.form ||
                  controller.viewMode == FitGridPlusViewMode.card) {
                controller.showEditDialog(context, rowIndex: rowIndex);
              } else {
                controller.startEditingRow(rowIndex);
              }
            },
          ),
        );
      }
      if (controller.editingOptions.allowDeleting) {
        items.add(
          createItem(
            label: 'Delete Row',
            icon: Icons.delete_outline_rounded,
            isDestructive: true,
            onTap: () => controller.deleteRow(rowIndex),
          ),
        );
      }
    }

    // 4. Custom Developer Actions
    final visibleCustom = config.customActions
        .where((act) => act.isVisible?.call(row, columnField) ?? true)
        .toList();

    if (visibleCustom.isNotEmpty) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider(height: 8));
      for (final action in visibleCustom) {
        items.add(
          createItem(
            label: action.label,
            icon: action.icon ?? Icons.play_arrow_outlined,
            isDestructive: action.isDestructive,
            onTap: () => action.onExecute(
              context,
              controller,
              row,
              rowIndex,
              columnField,
            ),
          ),
        );
      }
    }

    return items;
  }

  /// Displays the contextual popup menu at [position].
  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required FitGridPlusController controller,
    required Map<String, dynamic> row,
    required int rowIndex,
    String? columnField,
    dynamic cellValue,
  }) async {
    final items = buildMenuItems(
      context: context,
      controller: controller,
      row: row,
      rowIndex: rowIndex,
      columnField: columnField,
      cellValue: cellValue,
    );

    if (items.isEmpty || !context.mounted) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final overlaySize = overlay?.size ?? MediaQuery.of(context).size;

    await showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlaySize,
      ),
      items: items,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
