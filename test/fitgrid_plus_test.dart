import 'package:flutter_test/flutter_test.dart';
import 'package:fitgrid_plus/fitgrid_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FitGridPlus Model & Data Source Tests', () {
    test('LocalFitGridPlusDataSource loads rows and columns correctly', () async {
      final columns = [
        const FitGridPlusColumn(field: 'id', title: 'ID', type: FitGridPlusColumnType.number),
        const FitGridPlusColumn(field: 'name', title: 'Product Name', type: FitGridPlusColumnType.text),
        const FitGridPlusColumn(field: 'price', title: 'Price', type: FitGridPlusColumnType.currency),
        const FitGridPlusColumn(field: 'category', title: 'Category', type: FitGridPlusColumnType.text),
      ];

      final rows = [
        {'id': 1, 'name': 'Widget A', 'price': 25.50, 'category': 'Hardware'},
        {'id': 2, 'name': 'Widget B', 'price': 40.00, 'category': 'Software'},
        {'id': 3, 'name': 'Widget C', 'price': 15.25, 'category': 'Hardware'},
      ];

      final ds = LocalFitGridPlusDataSource(columns: columns, initialData: rows);
      expect(ds.columns.length, 4);
      final fetched = await ds.fetchRows();
      expect(fetched.length, 3);
      expect(fetched[0]['name'], 'Widget A');
    });

    test('FitGridPlusColumn validation rules operate correctly', () {
      final col = FitGridPlusColumn(
        field: 'email',
        title: 'Email Address',
        type: FitGridPlusColumnType.text,
        required: true,
        validator: (val) {
          if (val == null || !val.toString().contains('@')) {
            return 'Invalid email address';
          }
          return null;
        },
      );

      expect(col.validate(null), 'Email Address is required');
      expect(col.validate(''), 'Email Address is required');
      expect(col.validate('invalidemail'), 'Invalid email address');
      expect(col.validate('test@example.com'), isNull);
    });
  });

  group('FitGridPlusController Operation Tests', () {
    late FitGridPlusController controller;
    late List<FitGridPlusColumn> testColumns;
    late List<Map<String, dynamic>> testRows;

    setUp(() {
      controller = FitGridPlusController();
      testColumns = [
        const FitGridPlusColumn(
          field: 'id',
          title: 'ID',
          type: FitGridPlusColumnType.number,
          editable: false,
        ),
        const FitGridPlusColumn(
          field: 'name',
          title: 'Product',
          type: FitGridPlusColumnType.text,
          editable: true,
          required: true,
        ),
        const FitGridPlusColumn(
          field: 'price',
          title: 'Price',
          type: FitGridPlusColumnType.number,
          editable: true,
        ),
        const FitGridPlusColumn(
          field: 'category',
          title: 'Category',
          type: FitGridPlusColumnType.text,
          editable: true,
          isGroupable: true,
        ),
      ];

      testRows = [
        {'id': 101, 'name': 'Alpha', 'price': 100.0, 'category': 'Cat1'},
        {'id': 102, 'name': 'Beta', 'price': 200.0, 'category': 'Cat2'},
        {'id': 103, 'name': 'Gamma', 'price': 150.0, 'category': 'Cat1'},
        {'id': 104, 'name': 'Delta', 'price': 300.0, 'category': 'Cat2'},
      ];

      final ds = LocalFitGridPlusDataSource(columns: testColumns, initialData: testRows);
      controller.attach(
        columns: testColumns,
        dataSource: ds,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial controller state is loaded and rows are accessible', () {
      expect(controller.rows.length, 4);
      expect(controller.columns.length, 4);
      expect(controller.viewMode, FitGridPlusViewMode.grid);
      expect(controller.isPivotActive, isFalse);
    });

    test('Grouping by field activates hierarchical grouping', () {
      controller.setGrouping(['category']);
      expect(controller.activeGrouping, ['category']);
      controller.clearGrouping();
      expect(controller.activeGrouping, isEmpty);
    });

    test('Filtering operates accurately', () {
      controller.setFilter('category', operator: 'equals', value: 'Cat1');
      expect(controller.activeFilters.containsKey('category'), isTrue);
      controller.clearAllFilters();
      expect(controller.activeFilters, isEmpty);
    });

    test('Sorting by column sets active sort column and direction', () {
      controller.sort('price', descending: true);
      expect(controller.activeSortColumn, 'price');
      expect(controller.isSortDescending, isTrue);
      controller.clearSorting();
      expect(controller.activeSortColumn, isNull);
    });

    test('DevExtreme Edit Lifecycle: startEdit -> updateDraftValue -> saveEdit', () async {
      controller.setEditingOptions(
        const FitGridPlusEditingOptions(
          enabled: true,
          mode: FitGridPlusEditMode.row,
          allowUpdating: true,
        ),
      );

      controller.startEdit(0);
      expect(controller.isEditingRow, isTrue);
      expect(controller.editingRowIndex, 0);
      expect(controller.draftRow?['name'], 'Alpha');

      controller.updateDraftValue('name', 'Alpha-Modified');
      expect(controller.draftRow?['name'], 'Alpha-Modified');

      final err = await controller.saveEdit();
      expect(err, isNull);
      expect(controller.isEditingRow, isFalse);
      expect(controller.rows[0]['name'], 'Alpha-Modified');
    });

    test('Range summary calculation operates for selected rows', () {
      final summary = FitGridPlusRangeSummary.fromValues(
        rows: testRows,
        columnFields: ['price'],
      );

      expect(summary.cellCount, 4);
      expect(summary.numericCount, 4);
      expect(summary.sum, 750.0);
      expect(summary.average, 187.5);
      expect(summary.min, 100.0);
      expect(summary.max, 300.0);
    });

    test('Pivot Engine aggregates rows into dynamic matrix', () {
      const pivotConfig = FitGridPlusPivotConfig(
        rowFieldIds: ['category'],
        columnFieldIds: [],
        values: [
          FitGridPlusPivotValueField(
            columnId: 'price',
            label: 'Total Price',
            aggregation: FitGridPlusPivotAggregation.sum,
          ),
        ],
      );

      controller.setPivot(pivotConfig);
      expect(controller.isPivotActive, isTrue);
      expect(controller.pivotConfig, isNotNull);
      expect(controller.rows.length, 2); // 2 distinct categories: Cat1 and Cat2

      controller.clearPivot();
      expect(controller.isPivotActive, isFalse);
      expect(controller.rows.length, 4); // Restored original 4 rows
    });

    test('Deterministic Data Auditor detects issues and cleans data', () {
      final dirtyRows = [
        {'id': 1, 'name': 'Item A', 'price': 10.0},
        {'id': 1, 'name': 'Item A', 'price': 10.0}, // Duplicate
        {'id': 2, 'name': '  Item B  ', 'price': ' 20.5 '}, // Trailing spaces & type
      ];

      final report = FitGridPlusDataCleaner.audit(rows: dirtyRows, columns: testColumns);
      expect(report.totalRows, 3);
      expect(report.issues.isNotEmpty, isTrue);

      final cleaned = FitGridPlusDataCleaner.cleanAll(dirtyRows, columns: testColumns);
      expect(cleaned.length, 2); // Duplicate removed
      expect(cleaned[1]['name'], 'Item B'); // Trimmed
      expect(cleaned[1]['price'], 20.5); // Converted to double
    });
  });
}
