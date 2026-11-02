import 'package:material_ui/material_ui.dart';
import 'package:fitgrid_plus/fitgrid_plus.dart';

/// Feature 2: Conditional Formatting & In-Cell Canvas Visuals:
/// - In-cell horizontal data bars (sales volume)
/// - Profit color scale overrides (green positive, red negative)
/// - Target attainment progress bars
/// - In-cell canvas sparklines (trend lines)
class ConditionalFormattingExamplePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ConditionalFormattingExamplePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<ConditionalFormattingExamplePage> createState() =>
      _ConditionalFormattingExamplePageState();
}

class _ConditionalFormattingExamplePageState
    extends State<ConditionalFormattingExamplePage> {
  late final FitGridPlusController _controller;
  late final LocalFitGridPlusDataSource _dataSource;

  bool _showDataBars = true;
  bool _showSparklines = true;
  bool _showRowHighlights = true;

  @override
  void initState() {
    super.initState();
    _controller = FitGridPlusController();
    _setupGrid();
  }

  void _setupGrid() {
    final columns = [
      const FitGridPlusColumn(
        field: 'sku',
        title: 'SKU / Product',
        width: 170,
        type: FitGridPlusColumnType.text,
      ),
      const FitGridPlusColumn(
        field: 'category',
        title: 'Category',
        width: 140,
        type: FitGridPlusColumnType.select,
        selectOptions: ['Hardware', 'Software', 'Cloud Services', 'Consulting'],
      ),
      FitGridPlusColumn(
        field: 'sales',
        title: 'Sales (\$)',
        width: 150,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
        aggregateType: FitGridPlusAggregateType.sum,
        visual: _showDataBars
            ? FitGridPlusColumn.dataBar(
                color: const Color(0xFF1E88E5),
                min: 0,
                max: 120000,
                valueOf: (row) => row['sales'] as num?,
              )
            : null,
      ),
      FitGridPlusColumn(
        field: 'profit',
        title: 'Profit (\$)',
        width: 130,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
        aggregateType: FitGridPlusAggregateType.sum,
        cellColor: (value, row) {
          final p = value is num ? value : num.tryParse(value.toString()) ?? 0;
          if (p < 0) return const Color(0xFFD32F2F); // Red
          if (p > 25000) return const Color(0xFF2E7D32); // Green
          return null;
        },
        cellStyle: (value, row) {
          final p = value is num ? value : num.tryParse(value.toString()) ?? 0;
          if (p < 0) return const TextStyle(fontWeight: FontWeight.bold);
          return null;
        },
      ),
      FitGridPlusColumn(
        field: 'target_pct',
        title: 'Quota Attainment',
        width: 150,
        type: FitGridPlusColumnType.number,
        visual: FitGridPlusColumn.progress(
          fractionOf: (row) {
            final val = row['target_pct'];
            if (val is num) return (val / 100.0).clamp(0.0, 1.0);
            return 0.0;
          },
          color: const Color(0xFF107C41),
        ),
      ),
      FitGridPlusColumn(
        field: 'trend',
        title: '6-Month Trend',
        width: 140,
        type: _showSparklines
            ? FitGridPlusColumnType.sparkline
            : FitGridPlusColumnType.text,
        visual: _showSparklines
            ? FitGridPlusColumn.sparkline(
                valuesOf: (row) {
                  final list = row['trend'];
                  if (list is List<num>) return list;
                  return const <num>[];
                },
                color: const Color(0xFF0078D4),
                filled: true,
              )
            : null,
      ),
    ];

    final rows = [
      {
        'sku': 'Cloud Server Alpha',
        'category': 'Cloud Services',
        'sales': 95000.0,
        'profit': 32400.0,
        'target_pct': 95,
        'trend': [40, 55, 60, 75, 88, 95],
      },
      {
        'sku': 'Enterprise Database',
        'category': 'Software',
        'sales': 118000.0,
        'profit': 45200.0,
        'target_pct': 118,
        'trend': [80, 85, 90, 102, 110, 118],
      },
      {
        'sku': 'Legacy Mainframe M2',
        'category': 'Hardware',
        'sales': 42000.0,
        'profit': -8500.0,
        'target_pct': 42,
        'trend': [65, 58, 50, 48, 45, 42],
      },
      {
        'sku': 'DevOps Consulting Kit',
        'category': 'Consulting',
        'sales': 64000.0,
        'profit': 18900.0,
        'target_pct': 80,
        'trend': [30, 42, 50, 60, 72, 80],
      },
      {
        'sku': 'Quantum Edge Router',
        'category': 'Hardware',
        'sales': 89000.0,
        'profit': 24100.0,
        'target_pct': 89,
        'trend': [50, 62, 70, 75, 82, 89],
      },
      {
        'sku': 'AI Inference Accelerator',
        'category': 'Hardware',
        'sales': 112000.0,
        'profit': 38600.0,
        'target_pct': 112,
        'trend': [25, 40, 65, 80, 95, 112],
      },
      {
        'sku': 'Backup Storage Pod',
        'category': 'Hardware',
        'sales': 31000.0,
        'profit': -3200.0,
        'target_pct': 62,
        'trend': [55, 52, 48, 45, 40, 31],
      },
      {
        'sku': 'SaaS Analytics Pro',
        'category': 'Software',
        'sales': 78000.0,
        'profit': 28500.0,
        'target_pct': 98,
        'trend': [60, 68, 75, 82, 90, 98],
      },
    ];

    _dataSource = LocalFitGridPlusDataSource(
      columns: columns,
      initialData: rows,
      isReadonly: true,
    );
    if (_controller.isAttached) {
      _controller.attach(
        columns: columns,
        dataSource: _dataSource,
        notify: true,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                    Icon(Icons.palette_rounded, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Conditional Formatting & Visuals',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    FilterChip(
                      label: const Text('Data Bars'),
                      selected: _showDataBars,
                      onSelected: (bool val) {
                        setState(() {
                          _showDataBars = val;
                          _setupGrid();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Sparklines'),
                      selected: _showSparklines,
                      onSelected: (bool val) {
                        setState(() {
                          _showSparklines = val;
                          _setupGrid();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Highlight Loss'),
                      selected: _showRowHighlights,
                      onSelected: (bool val) {
                        setState(() {
                          _showRowHighlights = val;
                          _setupGrid();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FitGridPlus(
                key: ValueKey('$_showDataBars-$_showSparklines-$_showRowHighlights'),
                controller: _controller,
                dataSource: _dataSource,
                editingOptions: const FitGridPlusEditingOptions(enabled: false),
                showToolbar: true,
                cellSelection: true,
                rowColor: _showRowHighlights
                    ? (row, index) {
                        final p = row['profit'];
                        if (p is num && p < 0) {
                          return Colors.red.withAlpha(25);
                        }
                        return null;
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

