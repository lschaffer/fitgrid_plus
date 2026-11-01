import 'package:material_ui/material_ui.dart';
import 'package:fitgrid_plus/fitgrid_plus.dart';

import '../data/sample_sales_data.dart';

/// Feature 7: Mobile "Card / Feed" Responsive View
/// - 1-Tap Toggle between High-Performance Canvas DataGrid and Responsive Card Feed
/// - Rich card layout: primary title, status pill, customer, and key-value metrics
/// - Mobile touch swipe actions: swipe right to Edit, swipe left to Delete
class MobileCardViewExamplePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MobileCardViewExamplePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MobileCardViewExamplePage> createState() =>
      _MobileCardViewExamplePageState();
}

class _MobileCardViewExamplePageState extends State<MobileCardViewExamplePage> {
  late final FitGridPlusController _controller;
  late final LocalFitGridPlusDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _controller = FitGridPlusController();

    final columns = SampleSalesData.superstoreColumns;
    final rows = SampleSalesData.generateSuperstore1000(count: 100);

    _dataSource = LocalFitGridPlusDataSource(columns: columns, initialData: rows);
    _controller.setViewMode(FitGridPlusViewMode.card);

    _controller.setEditingOptions(
      FitGridPlusEditingOptions(
        enabled: true,
        mode: FitGridPlusEditMode.form,
        allowUpdating: true,
        allowDeleting: true,
        afterSave: (row) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Updated Order ${row['OrderID']}')),
            );
          }
        },
        afterDelete: (row) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted Order ${row['OrderID']}')),
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
                    Icon(Icons.view_agenda_rounded, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Mobile Card / Feed Responsive View',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        final isCard = _controller.viewMode == FitGridPlusViewMode.card;
                        return FilledButton.tonalIcon(
                          icon: Icon(
                            isCard ? Icons.table_chart_outlined : Icons.view_agenda_outlined,
                            size: 16,
                          ),
                          label: Text(isCard ? 'Switch to DataGrid' : 'Switch to Card Feed'),
                          onPressed: _controller.toggleViewMode,
                        );
                      },
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
                cardViewOptions: const FitGridPlusCardViewOptions(
                  titleField: 'OrderID',
                  subtitleField: 'SubCategory',
                  statusField: 'ShipMode',
                  spacing: 10.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

