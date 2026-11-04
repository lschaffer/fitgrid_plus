import 'package:material_ui/material_ui.dart';
import 'package:fitgrid_plus/fitgrid_plus.dart';

/// Feature 5: Pure-Dart Excel (.xlsx) Import & Export
/// - Zero C++ native dependencies, 100% pure Dart OpenXML parser
/// - Multi-sheet interactive selection dialog with row/col stats
/// - In-memory multi-sheet workbook generation
class ExcelImportExamplePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ExcelImportExamplePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<ExcelImportExamplePage> createState() => _ExcelImportExamplePageState();
}

class _ExcelImportExamplePageState extends State<ExcelImportExamplePage> {
  late final FitGridPlusController _controller;
  FitGridPlusExcelWorkbook? _currentWorkbook;
  String _activeSheetName = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = FitGridPlusController();

    // Load initial in-memory multi-sheet demo workbook
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDemoWorkbook(showPicker: false);
    });
  }

  Future<void> _loadDemoWorkbook({bool showPicker = true}) async {
    setState(() => _isLoading = true);
    try {
      final bytes = FitGridPlusExcelParser.createSampleMultiSheetWorkbookBytes();
      final wb = FitGridPlusExcelParser.parseBytes(
        bytes,
        fileName: 'Global_Retail_Performance_2026.xlsx',
      );
      _currentWorkbook = wb;

      FitGridPlusExcelSheet? targetSheet;
      if (showPicker && wb.isMultiSheet) {
        targetSheet = await FitGridPlusExcelSheetPickerDialog.show(
          context,
          workbook: wb,
          initialSheetName: _activeSheetName.isNotEmpty ? _activeSheetName : null,
        );
      } else {
        targetSheet = wb.primarySheet;
      }

      if (targetSheet != null) {
        _activeSheetName = targetSheet.name;
        _controller.loadExcelSheet(targetSheet, fileName: wb.fileName);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAnotherSheet() async {
    if (_currentWorkbook == null) return;
    final sheet = await FitGridPlusExcelSheetPickerDialog.show(
      context,
      workbook: _currentWorkbook!,
      initialSheetName: _activeSheetName,
    );
    if (sheet != null && mounted) {
      setState(() => _activeSheetName = sheet.name);
      _controller.loadExcelSheet(sheet, fileName: _currentWorkbook!.fileName);
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
                      const Icon(Icons.table_chart_rounded, color: Color(0xFF107C41), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Pure-Dart Excel (.xlsx) Ingestion',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_activeSheetName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Chip(
                          avatar: const Icon(Icons.description_outlined, size: 16),
                          label: Text('Sheet: $_activeSheetName'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.layers_outlined, size: 16),
                    label: const Text('Switch Worksheet'),
                    onPressed: _pickAnotherSheet,
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: const Text('Import Custom .xlsx'),
                    onPressed: () => _controller.importExcel(context: context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FitGridPlus(
                      controller: _controller,
                      dataSource: LocalFitGridPlusDataSource(
                        columns: _controller.columns,
                        initialData: _controller.rows,
                        isReadonly: true,
                      ),
                      editingOptions:
                          const FitGridPlusEditingOptions(enabled: false),
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

