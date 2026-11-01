import 'package:material_ui/material_ui.dart';

import '../controllers/fitgrid_plus_controller.dart';
import '../models/fitgrid_plus_column.dart';
import '../models/fitgrid_plus_pivot.dart';

/// DevExtreme-style Pivot Grid Field Chooser Dialog.
///
/// Allows visual configuration of:
/// 1. Row fields (vertical grouping dimensions)
/// 2. Column fields (horizontal grouping dimensions)
/// 3. Data fields / measures (with aggregation function selector)
/// 4. Side-by-side Chart options and Grand Totals
class FitGridPlusPivotChooserDialog extends StatefulWidget {
  const FitGridPlusPivotChooserDialog({super.key, required this.controller});

  final FitGridPlusController controller;

  /// Shows the dialog.
  static Future<void> show(BuildContext context, FitGridPlusController controller) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0x80000000),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        Widget content = FitGridPlusPivotChooserDialog(controller: controller);

        final hasLoc =
            Localizations.of<MaterialLocalizations>(
              dialogContext,
              MaterialLocalizations,
            ) !=
            null;
        if (!hasLoc) {
          content = Localizations(
            locale: const Locale('en', 'US'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: content,
          );
        }

        return SafeArea(child: content);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<FitGridPlusPivotChooserDialog> createState() =>
      _FitGridPlusPivotChooserDialogState();
}

class _FitGridPlusPivotChooserDialogState
    extends State<FitGridPlusPivotChooserDialog> {
  late List<String> _rowFieldIds;
  late List<String> _columnFieldIds;
  late List<FitGridPlusPivotValueField> _values;
  late bool _showColumnTotals;
  late bool _showChart;
  late FitGridPlusPivotChartType _chartType;
  late bool _groupByRows;
  String _searchFilter = '';

  static bool isCodeOrId(String field) {
    final lower = field.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return lower.contains('id') ||
        lower.contains('code') ||
        lower.contains('zip') ||
        lower.contains('postal') ||
        lower.contains('key') ||
        lower.contains('row') ||
        lower == 'no';
  }

  static bool isPreferredMeasure(String field) {
    final lower = field.toLowerCase();
    return lower.contains('sale') ||
        lower.contains('profit') ||
        lower.contains('quant') ||
        lower.contains('rev') ||
        lower.contains('amount') ||
        lower.contains('disc') ||
        lower.contains('cost') ||
        lower.contains('total') ||
        lower.contains('price') ||
        lower.contains('margin');
  }

  static bool isPreferredDimension(String field) {
    final lower = field.toLowerCase();
    return lower.contains('category') ||
        lower.contains('sub') ||
        lower.contains('region') ||
        lower.contains('segment') ||
        lower.contains('country') ||
        lower.contains('city') ||
        lower.contains('state') ||
        lower.contains('dept') ||
        lower.contains('department') ||
        lower.contains('type') ||
        lower.contains('status') ||
        lower.contains('mode');
  }

  @override
  void initState() {
    super.initState();
    final active = widget.controller.pivotConfig;
    if (active != null) {
      _rowFieldIds = List<String>.from(active.rowFieldIds);
      _columnFieldIds = List<String>.from(active.columnFieldIds);
      _values = List<FitGridPlusPivotValueField>.from(active.values);
      _showColumnTotals = active.showColumnTotals;
      _showChart = active.showChart;
      _chartType = active.chartType;
      _groupByRows = active.groupByRows;
    } else {
      _initSmartDefaults();
    }
  }

  void _initSmartDefaults() {
    final allCols = _availableColumns;

    final candidateMeasures = allCols.where((c) {
      if (isCodeOrId(c.field)) return false;
      return c.type == FitGridPlusColumnType.number ||
          c.type == FitGridPlusColumnType.currency ||
          isPreferredMeasure(c.field);
    }).toList();

    candidateMeasures.sort((a, b) {
      final aPref = isPreferredMeasure(a.field) ? 0 : 1;
      final bPref = isPreferredMeasure(b.field) ? 0 : 1;
      return aPref.compareTo(bPref);
    });

    final candidateDimensions = allCols.where((c) {
      if (isCodeOrId(c.field)) return false;
      return c.type == FitGridPlusColumnType.text ||
          c.type == FitGridPlusColumnType.select ||
          c.type == FitGridPlusColumnType.date ||
          isPreferredDimension(c.field);
    }).toList();

    candidateDimensions.sort((a, b) {
      final aPref = isPreferredDimension(a.field) ? 0 : 1;
      final bPref = isPreferredDimension(b.field) ? 0 : 1;
      return aPref.compareTo(bPref);
    });

    final catCol = candidateDimensions
        .where((c) => c.field.toLowerCase() == 'category')
        .firstOrNull;
    final subCatCol = candidateDimensions
        .where((c) => c.field.toLowerCase().contains('sub'))
        .firstOrNull;
    if (catCol != null) {
      _rowFieldIds = [catCol.field, if (subCatCol != null) subCatCol.field];
    } else if (candidateDimensions.isNotEmpty) {
      _rowFieldIds = [candidateDimensions.first.field];
    } else {
      _rowFieldIds = allCols.isNotEmpty ? [allCols.first.field] : [];
    }

    final regCol = candidateDimensions
        .where(
          (c) =>
              c.field.toLowerCase() == 'region' &&
              !_rowFieldIds.contains(c.field),
        )
        .firstOrNull;
    final segCol = candidateDimensions
        .where(
          (c) =>
              c.field.toLowerCase() == 'segment' &&
              !_rowFieldIds.contains(c.field),
        )
        .firstOrNull;
    if (regCol != null) {
      _columnFieldIds = [regCol.field];
    } else if (segCol != null) {
      _columnFieldIds = [segCol.field];
    } else {
      final nextDim = candidateDimensions
          .where((c) => !_rowFieldIds.contains(c.field))
          .firstOrNull;
      _columnFieldIds = nextDim != null ? [nextDim.field] : [];
    }

    final salesCol = candidateMeasures
        .where((c) => c.field.toLowerCase() == 'sales')
        .firstOrNull;
    final profitCol = candidateMeasures
        .where((c) => c.field.toLowerCase() == 'profit')
        .firstOrNull;
    final quantCol = candidateMeasures
        .where((c) => c.field.toLowerCase().contains('quant'))
        .firstOrNull;

    if (salesCol != null) {
      _values = [
        FitGridPlusPivotValueField(
          columnId: salesCol.field,
          aggregation: FitGridPlusPivotAggregation.sum,
        ),
        if (profitCol != null)
          FitGridPlusPivotValueField(
            columnId: profitCol.field,
            aggregation: FitGridPlusPivotAggregation.sum,
          )
        else if (quantCol != null)
          FitGridPlusPivotValueField(
            columnId: quantCol.field,
            aggregation: FitGridPlusPivotAggregation.sum,
          ),
      ];
    } else if (candidateMeasures.isNotEmpty) {
      _values = candidateMeasures
          .take(2)
          .map(
            (c) => FitGridPlusPivotValueField(
              columnId: c.field,
              aggregation: FitGridPlusPivotAggregation.sum,
            ),
          )
          .toList();
    } else {
      _values = allCols.isNotEmpty
          ? [
              FitGridPlusPivotValueField(
                columnId: allCols.last.field,
                aggregation: FitGridPlusPivotAggregation.count,
              ),
            ]
          : [];
    }

    _showColumnTotals = true;
    _showChart = true;
    _chartType = FitGridPlusPivotChartType.column;
    _groupByRows = true;
  }

  void _applyPreset({
    required List<String> rows,
    required List<String> columns,
    required List<FitGridPlusPivotValueField> values,
    FitGridPlusPivotChartType chartType = FitGridPlusPivotChartType.column,
  }) {
    final available = _availableColumns
        .map((c) => c.field.toLowerCase())
        .toSet();
    final validRows = rows
        .where((r) => available.contains(r.toLowerCase()))
        .toList();
    final validCols = columns
        .where((c) => available.contains(c.toLowerCase()))
        .toList();
    final validVals = values
        .where((v) => available.contains(v.columnId.toLowerCase()))
        .toList();

    setState(() {
      if (validRows.isNotEmpty) _rowFieldIds = validRows;
      _columnFieldIds = validCols;
      if (validVals.isNotEmpty) _values = validVals;
      _chartType = chartType;
      _showChart = true;
      _showColumnTotals = true;
      _groupByRows = true;
    });
  }

  List<FitGridPlusColumn> get _availableColumns {
    return widget.controller.originalColumns;
  }

  String _columnTitle(String field) {
    for (final col in _availableColumns) {
      if (col.field == field) return col.title;
    }
    return field;
  }

  void _apply() {
    if (_rowFieldIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one Row field.')),
      );
      return;
    }
    if (_values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one Data / Metric field.'),
        ),
      );
      return;
    }

    final config = FitGridPlusPivotConfig(
      rowFieldIds: _rowFieldIds,
      columnFieldIds: _columnFieldIds,
      values: _values,
      showColumnTotals: _showColumnTotals,
      showChart: _showChart,
      chartType: _chartType,
      groupByRows: _groupByRows,
    );

    widget.controller.setPivot(config);
    Navigator.of(context).pop();
  }

  void _reset() {
    widget.controller.clearPivot();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredColumns = _availableColumns.where((col) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return col.title.toLowerCase().contains(q) ||
          col.field.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D2D)
                    : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pivot_table_chart,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pivot Table Field Chooser',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: All Available Fields with Presets
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Quick Presets (DevExtreme Style)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            ActionChip(
                              visualDensity: VisualDensity.compact,
                              avatar: const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: Color(0xFF0078D4),
                              ),
                              label: const Text(
                                'Category x Region',
                                style: TextStyle(fontSize: 10),
                              ),
                              onPressed: () => _applyPreset(
                                rows: ['Category', 'SubCategory'],
                                columns: ['Region'],
                                values: const [
                                  FitGridPlusPivotValueField(
                                    columnId: 'Sales',
                                    aggregation: FitGridPlusPivotAggregation.sum,
                                  ),
                                  FitGridPlusPivotValueField(
                                    columnId: 'Profit',
                                    aggregation: FitGridPlusPivotAggregation.sum,
                                  ),
                                ],
                              ),
                            ),
                            ActionChip(
                              visualDensity: VisualDensity.compact,
                              avatar: const Icon(
                                Icons.pie_chart_outline,
                                size: 14,
                                color: Color(0xFF107C41),
                              ),
                              label: const Text(
                                'Segment x Ship',
                                style: TextStyle(fontSize: 10),
                              ),
                              onPressed: () => _applyPreset(
                                rows: ['Segment'],
                                columns: ['ShipMode'],
                                values: const [
                                  FitGridPlusPivotValueField(
                                    columnId: 'Sales',
                                    aggregation: FitGridPlusPivotAggregation.sum,
                                  ),
                                  FitGridPlusPivotValueField(
                                    columnId: 'Quantity',
                                    aggregation: FitGridPlusPivotAggregation.sum,
                                  ),
                                ],
                                chartType: FitGridPlusPivotChartType.groupedBar,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text(
                          'Available Fields',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search fields...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchFilter = val),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredColumns.length,
                            itemBuilder: (context, idx) {
                              final col = filteredColumns[idx];
                              final isNumeric =
                                  col.type == FitGridPlusColumnType.number ||
                                  col.type == FitGridPlusColumnType.currency;
                              final isMeasure =
                                  isNumeric && !isCodeOrId(col.field);

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 2.5,
                                ),
                                elevation: 0.5,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isMeasure
                                            ? Icons.calculate
                                            : (isCodeOrId(col.field)
                                                  ? Icons.fingerprint
                                                  : Icons.text_fields),
                                        size: 15,
                                        color: isMeasure
                                            ? Colors.teal
                                            : (isCodeOrId(col.field)
                                                  ? Colors.orange
                                                  : Colors.indigo),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              col.title,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              isMeasure
                                                  ? 'Measure'
                                                  : (isCodeOrId(col.field)
                                                        ? 'Identifier'
                                                        : 'Dimension'),
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isMeasure
                                                    ? Colors.teal
                                                    : (isCodeOrId(col.field)
                                                          ? Colors.orange
                                                          : Colors.grey[600]),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'Add to area',
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        onSelected: (target) {
                                          setState(() {
                                            if (target == 'row' &&
                                                !_rowFieldIds.contains(
                                                  col.field,
                                                )) {
                                              _rowFieldIds.add(col.field);
                                            } else if (target == 'col' &&
                                                !_columnFieldIds.contains(
                                                  col.field,
                                                )) {
                                              _columnFieldIds.add(col.field);
                                            } else if (target == 'data') {
                                              _values.add(
                                                FitGridPlusPivotValueField(
                                                  columnId: col.field,
                                                  aggregation: isNumeric
                                                      ? FitGridPlusPivotAggregation
                                                            .sum
                                                      : FitGridPlusPivotAggregation
                                                            .count,
                                                ),
                                              );
                                            }
                                          });
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'row',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.table_rows,
                                                  size: 16,
                                                  color: Colors.blue,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Add to Row Fields'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'col',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.view_column,
                                                  size: 16,
                                                  color: Colors.indigo,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Add to Column Fields'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'data',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calculate,
                                                  size: 16,
                                                  color: Colors.teal,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Add to Data / Measures'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: 3 Selection Zones
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildZone(
                            title: 'Row Fields (Tree & Vertical Grouping)',
                            icon: Icons.table_rows,
                            color: Colors.blue.shade700,
                            items: _rowFieldIds,
                            onRemove: (id) =>
                                setState(() => _rowFieldIds.remove(id)),
                          ),
                          const SizedBox(height: 12),

                          _buildZone(
                            title: 'Column Fields (Horizontal Breakdown)',
                            icon: Icons.view_column,
                            color: Colors.indigo.shade700,
                            items: _columnFieldIds,
                            onRemove: (id) =>
                                setState(() => _columnFieldIds.remove(id)),
                          ),
                          const SizedBox(height: 12),

                          Expanded(child: _buildDataMeasuresZone()),

                          const SizedBox(height: 10),
                          const Divider(),

                          // Options Row: Chart & Totals
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _showChart,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (v) =>
                                        setState(() => _showChart = v ?? false),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Auto-create Chart',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              if (_showChart)
                                DropdownButton<FitGridPlusPivotChartType>(
                                  value: _chartType,
                                  isDense: true,
                                  underline: const SizedBox.shrink(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  items: FitGridPlusPivotChartType.values.map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Text(t.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (t) {
                                    if (t != null) {
                                      setState(() => _chartType = t);
                                    }
                                  },
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _showColumnTotals,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (v) => setState(
                                      () => _showColumnTotals = v ?? true,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Grand Totals',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _groupByRows,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (v) => setState(
                                      () => _groupByRows = v ?? true,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Hierarchical Grouping',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252526)
                    : const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  if (widget.controller.isPivotActive)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Reset to Normal Table'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: _reset,
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Apply Pivot'),
                    onPressed: _apply,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZone({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required ValueChanged<String> onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withAlpha(80)),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'None (add from left panel)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final id in items)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    label: Text(
                      _columnTitle(id),
                      style: const TextStyle(fontSize: 11),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => onRemove(id),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDataMeasuresZone() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withAlpha(80)),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, size: 15, color: Colors.teal.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Data Fields / Measures (Aggregated Values)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_values.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No measures selected. Add numeric fields from left.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _values.length,
                itemBuilder: (context, idx) {
                  final val = _values[idx];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _columnTitle(val.columnId),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Aggregation Selector Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton<FitGridPlusPivotAggregation>(
                            value: val.aggregation,
                            underline: const SizedBox.shrink(),
                            isDense: true,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                            items: FitGridPlusPivotAggregation.values.map((agg) {
                              return DropdownMenuItem(
                                value: agg,
                                child: Text(agg.displayName),
                              );
                            }).toList(),
                            onChanged: (newAgg) {
                              if (newAgg != null) {
                                setState(() {
                                  _values[idx] = val.copyWith(
                                    aggregation: newAgg,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          tooltip: 'Remove',
                          onPressed: () {
                            setState(() => _values.removeAt(idx));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
