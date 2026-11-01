import 'dart:math';

import 'package:fitgrid_plus/fitgrid_plus.dart';

/// Provides realistic enterprise datasets for demonstration and showcase examples.
class SampleSalesData {
  SampleSalesData._();

  static const List<String> regions = [
    'North America',
    'Europe',
    'Asia Pacific',
    'Latin America',
    'Middle East',
    'Africa',
  ];

  static const List<String> categories = [
    'Technology',
    'Furniture',
    'Office Supplies',
  ];

  static const Map<String, List<String>> subcategoriesByCategory = {
    'Technology': ['Accessories', 'Laptops & PCs', 'Enterprise Servers', 'Mobile Phones', 'Wireless Headsets'],
    'Furniture': ['Ergonomic Chairs', 'Standing Desks', 'Bookcases', 'Conference Tables', 'Lamps'],
    'Office Supplies': ['Desk Organizers', 'Paper & Binders', 'Storage Boxes', 'Pens & Markers', 'Labels'],
  };

  static const List<String> segments = [
    'Consumer',
    'Corporate',
    'Home Office',
    'Enterprise',
  ];

  static const List<String> shipModes = [
    'Standard Class',
    'Second Class',
    'First Class',
    'Same Day',
  ];

  /// Standard column definitions for the 1,000-row Superstore enterprise dataset.
  static List<FitGridPlusColumn> get superstoreColumns => [
    const FitGridPlusColumn(
      field: 'OrderID',
      title: 'Order ID',
      width: 120,
      type: FitGridPlusColumnType.text,
      editable: false,
    ),
    const FitGridPlusColumn(
      field: 'OrderDate',
      title: 'Order Date',
      width: 110,
      type: FitGridPlusColumnType.date,
      editable: true,
    ),
    const FitGridPlusColumn(
      field: 'Region',
      title: 'Region',
      width: 130,
      type: FitGridPlusColumnType.select,
      selectOptions: regions,
      editable: true,
      isGroupable: true,
    ),
    const FitGridPlusColumn(
      field: 'Category',
      title: 'Category',
      width: 140,
      type: FitGridPlusColumnType.select,
      selectOptions: categories,
      editable: true,
      isGroupable: true,
    ),
    const FitGridPlusColumn(
      field: 'SubCategory',
      title: 'Sub-Category',
      width: 160,
      type: FitGridPlusColumnType.text,
      editable: true,
      isGroupable: true,
    ),
    const FitGridPlusColumn(
      field: 'Segment',
      title: 'Segment',
      width: 130,
      type: FitGridPlusColumnType.select,
      selectOptions: segments,
      editable: true,
      isGroupable: true,
    ),
    const FitGridPlusColumn(
      field: 'Sales',
      title: 'Sales (\$)',
      width: 130,
      type: FitGridPlusColumnType.currency,
      numberFormat: '#,##0.00',
      editable: true,
      aggregateType: FitGridPlusAggregateType.sum,
    ),
    const FitGridPlusColumn(
      field: 'Quantity',
      title: 'Quantity',
      width: 90,
      type: FitGridPlusColumnType.number,
      numberFormat: '#,###',
      editable: true,
      aggregateType: FitGridPlusAggregateType.sum,
    ),
    const FitGridPlusColumn(
      field: 'Discount',
      title: 'Discount',
      width: 100,
      type: FitGridPlusColumnType.number,
      numberFormat: '0.0%',
      editable: true,
      aggregateType: FitGridPlusAggregateType.average,
    ),
    const FitGridPlusColumn(
      field: 'Profit',
      title: 'Profit (\$)',
      width: 120,
      type: FitGridPlusColumnType.currency,
      numberFormat: '#,##0.00',
      editable: true,
      aggregateType: FitGridPlusAggregateType.sum,
    ),
    const FitGridPlusColumn(
      field: 'ShipMode',
      title: 'Ship Mode',
      width: 130,
      type: FitGridPlusColumnType.select,
      selectOptions: shipModes,
      editable: true,
    ),
  ];

  /// Generates 1,000 deterministic Superstore sales records.
  static List<Map<String, dynamic>> generateSuperstore1000({int count = 1000}) {
    final rand = Random(42);
    final rows = <Map<String, dynamic>>[];

    for (int i = 1; i <= count; i++) {
      final region = regions[rand.nextInt(regions.length)];
      final category = categories[rand.nextInt(categories.length)];
      final subCats = subcategoriesByCategory[category]!;
      final subCategory = subCats[rand.nextInt(subCats.length)];
      final segment = segments[rand.nextInt(segments.length)];
      final shipMode = shipModes[rand.nextInt(shipModes.length)];

      final year = 2024 + rand.nextInt(3);
      final month = (rand.nextInt(12) + 1).toString().padLeft(2, '0');
      final day = (rand.nextInt(28) + 1).toString().padLeft(2, '0');
      final date = '$year-$month-$day';

      final qty = rand.nextInt(12) + 1;
      final unitPrice = 15.0 + rand.nextInt(480);
      final discount = (rand.nextInt(4) * 0.05); // 0%, 5%, 10%, 15%
      final sales = double.parse((qty * unitPrice * (1.0 - discount)).toStringAsFixed(2));
      final profitMargin = 0.08 + (rand.nextDouble() * 0.32);
      final profit = double.parse((sales * profitMargin - (discount * sales * 0.4)).toStringAsFixed(2));

      rows.add({
        'OrderID': 'CA-$year-${(10000 + i)}',
        'OrderDate': date,
        'Region': region,
        'Category': category,
        'SubCategory': subCategory,
        'Segment': segment,
        'Sales': sales,
        'Quantity': qty,
        'Discount': discount,
        'Profit': profit,
        'ShipMode': shipMode,
      });
    }

    return rows;
  }
}

