import 'package:material_ui/material_ui.dart';

import 'utils/source_launcher.dart';
import 'dynamic_fitgrid_plus_example.dart';
import 'examples/superstore_enterprise_example.dart';
import 'examples/conditional_formatting_example.dart';
import 'examples/range_selection_example.dart';
import 'examples/master_detail_example.dart';
import 'examples/excel_import_example.dart';
import 'examples/data_auditor_example.dart';
import 'examples/mobile_card_view_example.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitGridPlusShowcaseApp());
}

/// Available showcase demos in the FitGrid Plus Gallery.
enum ShowcaseDemo {
  superstore(
    id: 'superstore',
    title: 'Flagship Superstore Grid',
    subtitle: 'DevExtreme editing, banded pivot matrix & canvas charts',
    icon: Icons.table_chart_rounded,
    badge: 'Flagship',
    sourceFilePath: 'example/lib/examples/superstore_enterprise_example.dart',
  ),
  conditionalFormatting(
    id: 'conditional_formatting',
    title: 'Feature 1: Conditional Formatting & Visuals',
    subtitle: 'In-cell data bars, profit colors, progress & sparklines',
    icon: Icons.palette_rounded,
    badge: 'Visuals',
    sourceFilePath: 'example/lib/examples/conditional_formatting_example.dart',
  ),
  rangeSelection(
    id: 'range_selection',
    title: 'Feature 2: Range Selection & Copy/Paste',
    subtitle: 'Excel-like drag selection, live summary metrics & TSV clipboard',
    icon: Icons.select_all_rounded,
    badge: 'Productivity',
    sourceFilePath: 'example/lib/examples/range_selection_example.dart',
  ),
  masterDetail(
    id: 'master_detail',
    title: 'Feature 3: Master-Detail Child Rows',
    subtitle: 'Expandable row details, nested grids & tabbed cards',
    icon: Icons.unfold_more_rounded,
    badge: 'Hierarchical',
    sourceFilePath: 'example/lib/examples/master_detail_example.dart',
  ),
  dynamicGrid(
    id: 'dynamic_grid',
    title: 'Feature 4: Dynamic Ingestion DataGrid',
    subtitle: 'Ingest from files (CSV, TSV, MD, JSON), Web GET & clipboard',
    icon: Icons.cloud_download_rounded,
    badge: 'Dynamic',
    sourceFilePath: 'example/lib/dynamic_fitgrid_plus_example.dart',
  ),
  excelImport(
    id: 'excel_import',
    title: 'Feature 5: Pure-Dart Excel (.xlsx) Ingestion',
    subtitle: 'Native workbook reading, multi-sheet selection & schema inference',
    icon: Icons.file_present_rounded,
    badge: 'Excel I/O',
    sourceFilePath: 'example/lib/examples/excel_import_example.dart',
  ),
  dataAuditor(
    id: 'data_auditor',
    title: 'Feature 6: Data Auditor & Cleaner',
    subtitle: 'Anomaly detection, duplicate cleaning & format cleanup',
    icon: Icons.health_and_safety_rounded,
    badge: 'Data Health',
    sourceFilePath: 'example/lib/examples/data_auditor_example.dart',
  ),
  mobileCardView(
    id: 'mobile_card_view',
    title: 'Feature 7: Mobile Card / Feed View',
    subtitle: '1-tap responsive switch between grid and feed card view',
    icon: Icons.view_agenda_rounded,
    badge: 'Responsive',
    sourceFilePath: 'example/lib/examples/mobile_card_view_example.dart',
  );

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final String sourceFilePath;

  const ShowcaseDemo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.sourceFilePath,
  });

  String get githubSourceUrl => '$kFitGridPlusRepoUrl/blob/main/$sourceFilePath';
}

class FitGridPlusShowcaseApp extends StatefulWidget {
  const FitGridPlusShowcaseApp({super.key});

  @override
  State<FitGridPlusShowcaseApp> createState() => _FitGridPlusShowcaseAppState();
}

class _FitGridPlusShowcaseAppState extends State<FitGridPlusShowcaseApp> {
  ThemeMode _themeMode = ThemeMode.light;
  ShowcaseDemo _currentDemo = ShowcaseDemo.superstore;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void _selectDemo(ShowcaseDemo demo) {
    setState(() {
      _currentDemo = demo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitGrid Plus - Enterprise Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078D4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078D4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: ShowcaseGalleryShell(
        currentDemo: _currentDemo,
        onSelectDemo: _selectDemo,
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class ShowcaseGalleryShell extends StatefulWidget {
  final ShowcaseDemo currentDemo;
  final ValueChanged<ShowcaseDemo> onSelectDemo;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ShowcaseGalleryShell({
    super.key,
    required this.currentDemo,
    required this.onSelectDemo,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<ShowcaseGalleryShell> createState() => _ShowcaseGalleryShellState();
}

class _ShowcaseGalleryShellState extends State<ShowcaseGalleryShell> {
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Toggle Navigation Menu',
            onPressed: () {
              if (isDesktop) {
                setState(() => _isSidebarVisible = !_isSidebarVisible);
              } else {
                Scaffold.of(ctx).openDrawer();
              }
            },
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.grid_on_rounded, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Text(
              widget.currentDemo.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ExampleSourceButton(
            relativeFilePath: widget.currentDemo.sourceFilePath,
            label: 'View Source',
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Open Repository on GitHub',
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            onPressed: () => launchSourceUrl(kFitGridPlusRepoUrl),
          ),
          IconButton(
            tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop && _isSidebarVisible) _buildSidebar(context),
          Expanded(child: _buildCurrentDemoView()),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on, color: Color(0xFF0078D4), size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'FitGrid Plus ⚡',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu_open, size: 18),
                      tooltip: 'Collapse Sidebar',
                      onPressed: () => setState(() => _isSidebarVisible = false),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pure Flutter Enterprise DataGrid with zero AI/LLM/MCP overhead.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: ShowcaseDemo.values.map((demo) {
                final isSelected = demo == widget.currentDemo;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withAlpha(120)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      demo.icon,
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      demo.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      demo.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Tooltip(
                      message: 'Source: ',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => launchSourceUrl(demo.githubSourceUrl),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.code_rounded,
                            size: 16,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                        ),
                      ),
                    ),
                    onTap: () => widget.onSelectDemo(demo),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.flash_on, color: Color(0xFF0078D4)),
              title: const Text('FitGrid Plus Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: ShowcaseDemo.values.map((demo) {
                  return ListTile(
                    leading: Icon(demo.icon),
                    title: Text(demo.title),
                    subtitle: Text(demo.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: demo == widget.currentDemo,
                    trailing: IconButton(
                      icon: const Icon(Icons.code_rounded, size: 18),
                      tooltip: 'View Source Code',
                      onPressed: () => launchSourceUrl(demo.githubSourceUrl),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelectDemo(demo);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDemoView() {
    switch (widget.currentDemo) {
      case ShowcaseDemo.superstore:
        return SuperstoreEnterpriseExamplePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        );
      case ShowcaseDemo.conditionalFormatting:
        return ConditionalFormattingExamplePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        );
      case ShowcaseDemo.rangeSelection:
        return RangeSelectionExamplePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        );
      case ShowcaseDemo.masterDetail:
        return MasterDetailExamplePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        );
      case ShowcaseDemo.dynamicGrid:
        return DynamicFitGridPlusExamplePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        );
      case ShowcaseDemo.excelImport:
        return ExcelImportExamplePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        );
      case ShowcaseDemo.dataAuditor:
        return DataAuditorExamplePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        );
      case ShowcaseDemo.mobileCardView:
        return MobileCardViewExamplePage(
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        );
    }
  }
}
