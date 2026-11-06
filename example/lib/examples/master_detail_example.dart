import '../utils/source_launcher.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fitgrid_plus/fitgrid_plus.dart';

/// Feature 3: Master-Detail Child Rows
/// - Expandable nested DataGrids
/// - Row key extraction and state management
/// - Child table showing individual line items
class MasterDetailExamplePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MasterDetailExamplePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MasterDetailExamplePage> createState() =>
      _MasterDetailExamplePageState();
}

class _MasterDetailExamplePageState extends State<MasterDetailExamplePage> {
  late final FitGridPlusController _controller;
  late final LocalFitGridPlusDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _controller = FitGridPlusController();

    final columns = [
      const FitGridPlusColumn(
        field: 'order_id',
        title: 'Order ID',
        width: 140,
        type: FitGridPlusColumnType.text,
      ),
      const FitGridPlusColumn(
        field: 'customer',
        title: 'Customer',
        width: 160,
        type: FitGridPlusColumnType.text,
      ),
      const FitGridPlusColumn(
        field: 'order_date',
        title: 'Date',
        width: 120,
        type: FitGridPlusColumnType.date,
      ),
      const FitGridPlusColumn(
        field: 'total_amount',
        title: 'Total (\$)',
        width: 130,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
        aggregateType: FitGridPlusAggregateType.sum,
      ),
      const FitGridPlusColumn(
        field: 'status',
        title: 'Status',
        width: 120,
        type: FitGridPlusColumnType.select,
        selectOptions: ['Delivered', 'In Transit', 'Processing', 'Cancelled'],
      ),
    ];

    final rows = [
      {
        'order_id': 'ORD-9021',
        'customer': 'Acme Corporation',
        'order_date': '2026-03-12',
        'total_amount': 4580.0,
        'status': 'Delivered',
        'items': [
          {'item_name': 'Ultra HD Monitor 32"', 'qty': 2, 'unit_price': 890.0, 'subtotal': 1780.0},
          {'item_name': 'Ergonomic Desk Pro', 'qty': 2, 'unit_price': 1400.0, 'subtotal': 2800.0},
        ],
      },
      {
        'order_id': 'ORD-9022',
        'customer': 'Globex Industries',
        'order_date': '2026-03-15',
        'total_amount': 2150.0,
        'status': 'In Transit',
        'items': [
          {'item_name': 'Mechanical Keyboards', 'qty': 10, 'unit_price': 115.0, 'subtotal': 1150.0},
          {'item_name': 'Precision Mice', 'qty': 10, 'unit_price': 100.0, 'subtotal': 1000.0},
        ],
      },
      {
        'order_id': 'ORD-9023',
        'customer': 'Stark Enterprise',
        'order_date': '2026-03-18',
        'total_amount': 12400.0,
        'status': 'Processing',
        'items': [
          {'item_name': 'Rack Server RX-800', 'qty': 2, 'unit_price': 5200.0, 'subtotal': 10400.0},
          {'item_name': 'Optical SFP+ Modules', 'qty': 8, 'unit_price': 250.0, 'subtotal': 2000.0},
        ],
      },
      {
        'order_id': 'ORD-9024',
        'customer': 'Wayne Tech',
        'order_date': '2026-03-20',
        'total_amount': 3800.0,
        'status': 'Delivered',
        'items': [
          {'item_name': 'Executive Chair Stealth', 'qty': 4, 'unit_price': 950.0, 'subtotal': 3800.0},
        ],
      },
    ];

    _dataSource = LocalFitGridPlusDataSource(
      columns: columns,
      initialData: rows,
      isReadonly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildNestedDetailGrid(BuildContext context, Map<String, dynamic> row) {
    final items = (row['items'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];

    final childColumns = [
      const FitGridPlusColumn(
        field: 'item_name',
        title: 'Item Description',
        width: 220,
        type: FitGridPlusColumnType.text,
      ),
      const FitGridPlusColumn(
        field: 'qty',
        title: 'Quantity',
        width: 100,
        type: FitGridPlusColumnType.number,
      ),
      const FitGridPlusColumn(
        field: 'unit_price',
        title: 'Unit Price',
        width: 130,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
      ),
      const FitGridPlusColumn(
        field: 'subtotal',
        title: 'Line Subtotal',
        width: 140,
        type: FitGridPlusColumnType.currency,
        numberFormat: '#,##0.00',
      ),
    ];

    final childSource = LocalFitGridPlusDataSource(
      columns: childColumns,
      initialData: items,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(90),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Order Details for ${row['order_id']} (${items.length} items)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FitGridPlus(
              dataSource: childSource,
              editingOptions: const FitGridPlusEditingOptions(enabled: false),
              showToolbar: false,
              cellSelection: false,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
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
                      Icon(Icons.unfold_more_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Master-Detail Child Rows & Nested Grids',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const ExampleSourceButton(
                    relativeFilePath: 'example/lib/examples/master_detail_example.dart',
                  ),
                ],
              ),
            ),
            Expanded(
              child: FitGridPlus(
                controller: _controller,
                dataSource: _dataSource,
                editingOptions: const FitGridPlusEditingOptions(enabled: false),
                showToolbar: true,
                masterDetailOptions: FitGridPlusMasterDetailOptions(
                  rowKey: (row) => row['order_id'] as Object,
                  detailBuilder: (context, row, rowIndex) =>
                      _buildNestedDetailGrid(context, row),
                  detailRowHeight: 220.0,
                  initiallyExpandedKeys: const {'ORD-9021'},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

