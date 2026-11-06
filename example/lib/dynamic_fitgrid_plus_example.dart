import 'utils/source_launcher.dart';
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
  FitGridPlusDataSource? _dataSource;

  static const String _sampleCsv = '''Employee ID,Full Name,Department,Salary,Hire Date,Active
EMP-101,Alice Johnson,Engineering,125000,2022-03-15,true
EMP-102,Bob Smith,Marketing,85000,2021-06-01,true
EMP-103,Charlie Davis,Engineering,135000,2020-01-10,true
EMP-104,Diana Prince,Sales,95000,2023-04-18,true
EMP-105,Evan Wright,Product,110000,2022-11-05,false
EMP-106,Fiona Gallagher,Human Resources,78000,2021-09-20,true
EMP-107,George Clark,Finance,118000,2019-08-12,true''';

  static const String _sampleYaml = '''metadata:
  title: Cloud Infrastructure Fleet
model:
  id: cloud_fleet
  title: Cloud Infrastructure Fleet
  columns:
    - field: server_id
      title: Server ID
      type: text
    - field: hostname
      title: Hostname
      type: text
    - field: region
      title: Cloud Region
      type: text
    - field: status
      title: Health Status
      type: text
    - field: cpu_cores
      title: Cores
      type: number
    - field: memory_gb
      title: RAM (GB)
      type: number
    - field: monthly_cost
      title: Cost (\$)
      type: currency
data:
  - {"server_id": "SRV-1001", "hostname": "us-east-web-01", "region": "us-east-1", "status": "Active", "cpu_cores": 16, "memory_gb": 64, "monthly_cost": 240.0}
  - {"server_id": "SRV-1002", "hostname": "us-east-db-01", "region": "us-east-1", "status": "Active", "cpu_cores": 64, "memory_gb": 256, "monthly_cost": 980.0}
  - {"server_id": "SRV-1003", "hostname": "eu-west-web-01", "region": "eu-west-1", "status": "Active", "cpu_cores": 16, "memory_gb": 64, "monthly_cost": 260.0}
  - {"server_id": "SRV-1004", "hostname": "eu-west-cache-01", "region": "eu-west-1", "status": "Maintenance", "cpu_cores": 32, "memory_gb": 128, "monthly_cost": 520.0}
  - {"server_id": "SRV-1005", "hostname": "ap-south-worker-01", "region": "ap-south-1", "status": "Active", "cpu_cores": 32, "memory_gb": 128, "monthly_cost": 490.0}
''';

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

    final ds = LocalFitGridPlusDataSource(
      columns: columns,
      initialData: parsed.rows,
      isReadonly: false,
    );
    setState(() {
      _dataSource = ds;
    });
    _controller.loadDynamicDatasource(
      FitGridPlusDynamicDescriptor(
        name: 'sample_employees_csv',
        title: 'Employees Directory',
        isReadonly: false,
        sourceType: 'csv',
      ),
      columns,
      parsed.rows,
    );
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
      final ds = LocalFitGridPlusDataSource(
        columns: columns,
        initialData: parsed.rows,
        isReadonly: false,
      );
      setState(() {
        _dataSource = ds;
      });
      _controller.loadDynamicDatasource(
        FitGridPlusDynamicDescriptor(
          name: 'sample_server_metrics_md',
          title: 'Server Metrics',
          isReadonly: false,
          sourceType: 'markdown',
        ),
        columns,
        parsed.rows,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loaded Markdown Server Metrics table!')),
        );
      }
    }
  }

  void _loadYamlSample() {
    final bundle = FitGridPlusDynamicBundle.fromYamlString(_sampleYaml);
    final columns = bundle.model.toColumns();
    final ds = LocalFitGridPlusDataSource(
      columns: columns,
      initialData: bundle.rows,
      isReadonly: false,
    );
    setState(() {
      _dataSource = ds;
    });
    _controller.loadDynamicDatasource(
      bundle.model.toDescriptor(rowCount: bundle.rows.length),
      columns,
      bundle.rows,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loaded YAML Cloud Fleet table!')),
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
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_download_rounded, color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Dynamic Ingestion DataGrid',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.table_rows_outlined, size: 16),
                    label: const Text('Load CSV Sample'),
                    onPressed: _loadInitialDelimitedData,
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.text_snippet_outlined, size: 16),
                    label: const Text('Load Markdown Table'),
                    onPressed: _loadMarkdownSample,
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.data_object_outlined, size: 16),
                    label: const Text('Load YAML Sample'),
                    onPressed: _loadYamlSample,
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Edit Columns'),
                    onPressed: () => _controller.showColumnsEditorDialog(context),
                  ),
                  const ExampleSourceButton(
                    relativeFilePath: 'example/lib/dynamic_fitgrid_plus_example.dart',
                  ),
                ],
              ),
            ),
            Expanded(
              child: FitGridPlus(
                controller: _controller,
                dataSource: _dataSource ??
                    _controller.dataSource ??
                    LocalFitGridPlusDataSource(
                      columns: const [],
                      initialData: const [],
                      isReadonly: false,
                    ),
                editingOptions: const FitGridPlusEditingOptions(
                  enabled: true,
                  allowUpdating: true,
                  mode: FitGridPlusEditMode.cell,
                ),
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

