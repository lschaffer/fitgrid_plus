import 'package:material_ui/material_ui.dart';
import 'package:fitgrid_plus/fitgrid_plus.dart';

import '../data/sample_sales_data.dart';

/// Flagship Superstore Enterprise Showcase:
/// - DevExtreme-style multi-mode editing (cell inline, row inline, and modal popup form)
/// - Dynamic Pivot Grid with banded column headers
/// - Moveable canvas split charts (Grouped Bar, Column, Line Trend, Pie)
/// - Multi-level hierarchical grouping with top chip panel
/// - Pure Dart Excel (.xlsx) export
class SuperstoreEnterpriseExamplePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const SuperstoreEnterpriseExamplePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<SuperstoreEnterpriseExamplePage> createState() =>
      _SuperstoreEnterpriseExamplePageState();
}

class _SuperstoreEnterpriseExamplePageState
    extends State<SuperstoreEnterpriseExamplePage> {
  late final FitGridPlusController _controller;
  late final LocalFitGridPlusDataSource _dataSource;
  FitGridPlusEditMode _editMode = FitGridPlusEditMode.row;
  bool _isPagingEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = FitGridPlusController();

    final columns = SampleSalesData.superstoreColumns;
    final rows = SampleSalesData.generateSuperstore1000(count: 1000);

    _dataSource = LocalFitGridPlusDataSource(columns: columns, initialData: rows);
    _updateEditingOptions();

    // Default grouping: Region -> Category
    _controller.setGrouping(['Region', 'Category']);
  }

  void _updateEditingOptions() {
    _controller.setEditingOptions(
      FitGridPlusEditingOptions(
        enabled: true,
        mode: _editMode,
        allowAdding: true,
        allowUpdating: true,
        allowDeleting: true,
        actionColumnPosition: FitGridPlusActionColumnPosition.right,
        formLayout: const FitGridPlusFormLayout.grid(columns: 2),
        afterSave: (row) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Record ${row['OrderID'] ?? ''} saved successfully!'),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        afterDelete: (row) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Record ${row['OrderID'] ?? ''} deleted.'),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyQuickPivot() {
    const pivotConfig = FitGridPlusPivotConfig(
      rowFieldIds: ['Region', 'Category'],
      columnFieldIds: ['Segment'],
      values: [
        FitGridPlusPivotValueField(
          columnId: 'Sales',
          label: 'Total Sales',
          aggregation: FitGridPlusPivotAggregation.sum,
        ),
        FitGridPlusPivotValueField(
          columnId: 'Profit',
          label: 'Total Profit',
          aggregation: FitGridPlusPivotAggregation.sum,
        ),
      ],
      showColumnTotals: true,
      showRowTotals: true,
      showChart: true,
      chartType: FitGridPlusPivotChartType.groupedBar,
    );

    _controller.setPivot(pivotConfig);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top control strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.table_chart_rounded, color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Superstore Enterprise Grid',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '1,000 Records',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Edit mode segmented control
                  SegmentedButton<FitGridPlusEditMode>(
                    segments: const [
                      ButtonSegment(
                        value: FitGridPlusEditMode.cell,
                        label: Text('Cell Edit'),
                        icon: Icon(Icons.touch_app_outlined, size: 15),
                      ),
                      ButtonSegment(
                        value: FitGridPlusEditMode.row,
                        label: Text('Row Edit'),
                        icon: Icon(Icons.edit_note, size: 15),
                      ),
                      ButtonSegment(
                        value: FitGridPlusEditMode.form,
                        label: Text('Form Popup'),
                        icon: Icon(Icons.open_in_browser, size: 15),
                      ),
                    ],
                    selected: {_editMode},
                    onSelectionChanged: (Set<FitGridPlusEditMode> selected) {
                      setState(() {
                        _editMode = selected.first;
                        _updateEditingOptions();
                      });
                    },
                  ),
                  // Paging Checkbox
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isPagingEnabled = !_isPagingEnabled;
                        _controller.setPagination(_isPagingEnabled, pageSize: 25);
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _isPagingEnabled,
                            onChanged: (val) {
                              setState(() {
                                _isPagingEnabled = val ?? false;
                                _controller.setPagination(_isPagingEnabled, pageSize: 25);
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Paging (25)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      if (_controller.isPivotActive) {
                        return FilledButton.tonalIcon(
                          icon: const Icon(Icons.undo, size: 16),
                          label: const Text('Exit Pivot'),
                          onPressed: _controller.clearPivot,
                        );
                      }
                      return FilledButton.icon(
                        icon: const Icon(Icons.pivot_table_chart, size: 16),
                        label: const Text('Quick Pivot'),
                        onPressed: _applyQuickPivot,
                      );
                    },
                  ),
                ],
              ),
            ),
            // The Main FitGridPlus DataGrid
            Expanded(
              child: FitGridPlus(
                controller: _controller,
                dataSource: _dataSource,
                showToolbar: true,
                cellSelection: true,
                showSelectionStatusBar: true,
                enablePagination: _isPagingEnabled,
                pageSize: 25,
                autoSave: true,
                persistenceKey: 'fitgrid_plus_superstore_demo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

