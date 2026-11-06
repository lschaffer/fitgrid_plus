import '../utils/source_launcher.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fitgrid_plus/fitgrid_plus.dart';

/// Feature 6: Data Auditor & Anomaly Cleaner
/// - Real-time Data Quality Health Score
/// - Deterministic anomaly detection: duplicates, dirty currency symbols,
///   inconsistent whitespace, mixed date formats, missing values, and outliers.
/// - Interactive modal dialog with 1-click remediation.
class DataAuditorExamplePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const DataAuditorExamplePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<DataAuditorExamplePage> createState() => _DataAuditorExamplePageState();
}

class _DataAuditorExamplePageState extends State<DataAuditorExamplePage> {
  late final FitGridPlusController _controller;
  FitGridPlusAuditReport? _currentReport;

  @override
  void initState() {
    super.initState();
    _controller = FitGridPlusController();
    _loadDirtyDataset();
  }

  void _loadDirtyDataset() {
    final columns = [
      const FitGridPlusColumn(
        field: 'order_id',
        title: 'Order ID',
        type: FitGridPlusColumnType.text,
        width: 120,
        editable: true,
      ),
      const FitGridPlusColumn(
        field: 'order_date',
        title: 'Order Date',
        type: FitGridPlusColumnType.date,
        width: 140,
        editable: true,
      ),
      const FitGridPlusColumn(
        field: 'customer',
        title: 'Customer Name',
        type: FitGridPlusColumnType.text,
        width: 170,
        editable: true,
      ),
      const FitGridPlusColumn(
        field: 'revenue',
        title: 'Revenue (\$)',
        type: FitGridPlusColumnType.currency,
        width: 140,
        editable: true,
      ),
      const FitGridPlusColumn(
        field: 'discount',
        title: 'Discount',
        type: FitGridPlusColumnType.number,
        width: 120,
        editable: true,
      ),
      const FitGridPlusColumn(
        field: 'status',
        title: 'Status',
        type: FitGridPlusColumnType.text,
        width: 130,
        editable: true,
      ),
    ];

    // Intentional data quality issues: duplicates, trailing spaces, dirty currency strings, mixed dates
    final dirtyRows = [
      {'order_id': 'ORD-101', 'order_date': '2026-01-15', 'customer': 'Acme Inc.', 'revenue': 1420.50, 'discount': 0.05, 'status': 'Shipped'},
      {'order_id': 'ORD-101', 'order_date': '2026-01-15', 'customer': 'Acme Inc.', 'revenue': 1420.50, 'discount': 0.05, 'status': 'Shipped'}, // Duplicate
      {'order_id': 'ORD-102', 'order_date': '15/02/2026', 'customer': '  Beta Global  ', 'revenue': '\$ 2,350.00', 'discount': 0.10, 'status': 'Delivered'}, // Whitespace & dirty currency & non-iso date
      {'order_id': 'ORD-103', 'order_date': '2026-02-20', 'customer': 'Gamma Corp', 'revenue': 980.00, 'discount': 0.0, 'status': 'Pending'},
      {'order_id': 'ORD-104', 'order_date': 'March 5, 2026', 'customer': 'Delta Ltd  ', 'revenue': 3400.00, 'discount': 0.15, 'status': 'Shipped'}, // Date & space
      {'order_id': 'ORD-105', 'order_date': '2026-03-10', 'customer': 'Epsilon Systems', 'revenue': '4,500.50 EUR', 'discount': 0.05, 'status': 'Delivered'}, // Dirty number
      {'order_id': 'ORD-106', 'order_date': '2026-03-12', 'customer': 'Zeta Partners', 'revenue': 850.00, 'discount': null, 'status': 'Processing'}, // Missing value
      {'order_id': 'ORD-107', 'order_date': '2026-03-18', 'customer': 'Eta Dynamics', 'revenue': 125000.00, 'discount': 0.20, 'status': 'Shipped'}, // Statistical Outlier
    ];

    final ds = LocalFitGridPlusDataSource(columns: columns, initialData: dirtyRows);
    _controller.attach(columns: columns, dataSource: ds);
    _runAudit();
  }

  void _runAudit() {
    final report = FitGridPlusDataCleaner.audit(
      rows: _controller.rows,
      columns: _controller.columns,
    );
    setState(() => _currentReport = report);
  }

  Future<void> _openAuditorDialog() async {
    final result = await _controller.showDataAuditorDialog(context);
    if (result != null && mounted) {
      _runAudit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cleanAllDirectly() {
    final res = _controller.cleanAllData();
    _runAudit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
        ),
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
    final score = _currentReport?.overallScore ?? 100;
    final scoreColor = score >= 90
        ? Colors.green
        : (score >= 70 ? Colors.orange : Colors.red);

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
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: scoreColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Data Quality Auditor & Cleaner',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scoreColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scoreColor.withAlpha(120)),
                        ),
                        child: Text(
                          'Health Score: $score%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset Dirty Data'),
                    onPressed: _loadDirtyDataset,
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('1-Click Clean All'),
                    onPressed: _cleanAllDirectly,
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.troubleshoot, size: 16),
                    label: const Text('Inspect Anomaly Report'),
                    onPressed: _openAuditorDialog,
                  ),
                  const ExampleSourceButton(
                    relativeFilePath: 'example/lib/examples/data_auditor_example.dart',
                  ),
                ],
              ),
            ),
            Expanded(
              child: FitGridPlus(
                controller: _controller,
                dataSource: _controller.dataSource!,
                editingOptions: const FitGridPlusEditingOptions(enabled: false),
                showToolbar: true,
                cellSelection: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

