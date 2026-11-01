import 'package:material_ui/material_ui.dart';
import 'package:fitgrid_plus/fitgrid_plus.dart';

/// Feature 4: Range Selection & Statistical Aggregation
/// - Excel-like rectangular cell drag selection
/// - Live footer status bar with Count, Sum, Average, Min, and Max
/// - Single-click "Copy Range" (Ctrl+C / TSV clipboard)
class RangeSelectionExamplePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const RangeSelectionExamplePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<RangeSelectionExamplePage> createState() =>
      _RangeSelectionExamplePageState();
}

class _RangeSelectionExamplePageState extends State<RangeSelectionExamplePage> {
  late final FitGridPlusController _controller;
  late final LocalFitGridPlusDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _controller = FitGridPlusController();

    final columns = [
      const FitGridPlusColumn(
        field: 'product',
        title: 'Product / Line Item',
        width: 180,
        type: FitGridPlusColumnType.text,
      ),
      const FitGridPlusColumn(
        field: 'region',
        title: 'Region',
        width: 130,
        type: FitGridPlusColumnType.select,
        selectOptions: ['North America', 'EMEA', 'APAC', 'LATAM'],
      ),
      const FitGridPlusColumn(
        field: 'q1',
        title: 'Q1 Revenue',
        width: 130,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
        aggregateType: FitGridPlusAggregateType.sum,
      ),
      const FitGridPlusColumn(
        field: 'q2',
        title: 'Q2 Revenue',
        width: 130,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
        aggregateType: FitGridPlusAggregateType.sum,
      ),
      const FitGridPlusColumn(
        field: 'q3',
        title: 'Q3 Revenue',
        width: 130,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
        aggregateType: FitGridPlusAggregateType.sum,
      ),
      const FitGridPlusColumn(
        field: 'q4',
        title: 'Q4 Revenue',
        width: 130,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
        aggregateType: FitGridPlusAggregateType.sum,
      ),
      const FitGridPlusColumn(
        field: 'total',
        title: 'Total Annual',
        width: 140,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
        aggregateType: FitGridPlusAggregateType.sum,
      ),
    ];

    final rows = [
      {
        'product': 'Cloud Suite Ultimate',
        'region': 'North America',
        'q1': 142000.0,
        'q2': 158000.0,
        'q3': 175000.0,
        'q4': 210000.0,
        'total': 685000.0,
      },
      {
        'product': 'Security Sentinel',
        'region': 'EMEA',
        'q1': 89000.0,
        'q2': 94000.0,
        'q3': 105000.0,
        'q4': 122000.0,
        'total': 410000.0,
      },
      {
        'product': 'Data Mesh Gateway',
        'region': 'APAC',
        'q1': 67000.0,
        'q2': 78000.0,
        'q3': 85000.0,
        'q4': 98000.0,
        'total': 328000.0,
      },
      {
        'product': 'IoT Telemetry Core',
        'region': 'LATAM',
        'q1': 45000.0,
        'q2': 51000.0,
        'q3': 58000.0,
        'q4': 64000.0,
        'total': 218000.0,
      },
      {
        'product': 'Identity Access Mgr',
        'region': 'North America',
        'q1': 112000.0,
        'q2': 125000.0,
        'q3': 138000.0,
        'q4': 165000.0,
        'total': 540000.0,
      },
      {
        'product': 'Edge Computing Node',
        'region': 'EMEA',
        'q1': 95000.0,
        'q2': 102000.0,
        'q3': 118000.0,
        'q4': 130000.0,
        'total': 445000.0,
      },
      {
        'product': 'Disaster Recovery Pod',
        'region': 'APAC',
        'q1': 72000.0,
        'q2': 81000.0,
        'q3': 89000.0,
        'q4': 99000.0,
        'total': 341000.0,
      },
      {
        'product': 'API Monetization Engine',
        'region': 'North America',
        'q1': 128000.0,
        'q2': 140000.0,
        'q3': 155000.0,
        'q4': 188000.0,
        'total': 611000.0,
      },
    ];

    _dataSource = LocalFitGridPlusDataSource(columns: columns, initialData: rows);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectQ1Q4Block() {
    // Select block row 0 to 4, columns q1 through q4
    _controller.selectCellRange(
      anchorRow: 0,
      anchorColumn: 'q1',
      extentRow: 4,
      extentColumn: 'q4',
    );
  }

  Future<void> _copySelectedRange() async {
    final success = await _controller.copySelectedRangeToClipboard(includeHeaders: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Selected range copied to clipboard as TSV!'
                : 'No cell range selected to copy.',
          ),
          backgroundColor: success ? Colors.green.shade700 : Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(Icons.select_all_rounded, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Range Selection & Summary Metrics',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.flash_on_outlined, size: 16),
                      label: const Text('Select Q1-Q4 Block'),
                      onPressed: _selectQ1Q4Block,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Selection (TSV)'),
                      onPressed: _copySelectedRange,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FitGridPlus(
                controller: _controller,
                dataSource: _dataSource,
                showToolbar: true,
                cellSelection: true,
                showSelectionStatusBar: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

