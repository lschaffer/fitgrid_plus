import 'package:material_ui/material_ui.dart';
import 'package:fitgrid_plus/fitgrid_plus.dart';

/// Dynamic Ingestion DataGrid:
/// - Ingest datasets on-the-fly from CSV, TSV, JSON, or Markdown text
/// - Persistent layout and schema storage via SharedPreferences
/// - Columns editor and metadata manager dialogs
class DynamicFitGridPlusExamplePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const DynamicFitGridPlusExamplePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<DynamicFitGridPlusExamplePage> createState() =>
      _DynamicFitGridPlusExamplePageState();
}

class _DynamicFitGridPlusExamplePageState
    extends State<DynamicFitGridPlusExamplePage> {
  late final FitGridPlusController _controller;

  static const String _sampleCsv = '''Employee ID,Full Name,Department,Salary,Hire Date,Active
EMP-101,Alice Johnson,Engineering,125000,2022-03-15,true
EMP-102,Bob Smith,Marketing,85000,2021-06-01,true
EMP-103,Charlie Davis,Engineering,135000,2020-01-10,true
EMP-104,Diana Prince,Sales,95000,2023-04-18,true
EMP-105,Evan Wright,Product,110000,2022-11-05,false
EMP-106,Fiona Gallagher,Human Resources,78000,2021-09-20,true
EMP-107,George Clark,Finance,118000,2019-08-12,true''';

  @override
  void initState() {
    super.initState();
    _controller = FitGridPlusController();
    _loadInitialDelimitedData();
  }

  void _loadInitialDelimitedData() {
    final parsed = DelimitedTableParser.parse(_sampleCsv);
    final columns = parsed.columns
        .map((c) => c.toFitGridPlusColumn())
        .toList();

    final ds = LocalFitGridPlusDataSource(columns: columns, initialData: parsed.rows);
    _controller.attach(columns: columns, dataSource: ds);
  }

  void _loadMarkdownSample() {
    const md = '''
| Server Name | IP Address | Status | CPU Load | Memory (GB) |
| :--- | :--- | :--- | :--- | :--- |
| prod-app-01 | 10.0.1.15 | Healthy | 42% | 64 |
| prod-app-02 | 10.0.1.16 | Healthy | 38% | 64 |
| prod-db-primary | 10.0.2.10 | Warning | 88% | 256 |
| prod-db-replica | 10.0.2.11 | Healthy | 25% | 256 |
| cache-cluster-01 | 10.0.3.50 | Critical | 96% | 128 |
| backup-agent | 10.0.4.5 | Healthy | 12% | 32 |
''';

    final parsed = MarkdownTableExtractor.extractFirst(md);
    if (parsed != null) {
      final columns = parsed.columns
          .map((c) => c.toFitGridPlusColumn())
          .toList();
      final ds = LocalFitGridPlusDataSource(columns: columns, initialData: parsed.rows);
      _controller.attach(columns: columns, dataSource: ds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loaded Markdown Server Metrics table!')),
        );
      }
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
                    Icon(Icons.cloud_download_rounded, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Dynamic Ingestion DataGrid',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.table_rows_outlined, size: 16),
                      label: const Text('Load CSV Sample'),
                      onPressed: _loadInitialDelimitedData,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.text_snippet_outlined, size: 16),
                      label: const Text('Load Markdown Table'),
                      onPressed: _loadMarkdownSample,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.manage_history, size: 16),
                      label: const Text('Datasource Manager'),
                      onPressed: () =>
                          FitGridPlusDatasourceManagerDialog.show(context, _controller),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FitGridPlus(
                controller: _controller,
                dataSource: _controller.dataSource ??
                    LocalFitGridPlusDataSource(columns: const [], initialData: const []),
                showToolbar: true,
                dynamicGrid: true,
                cellSelection: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

