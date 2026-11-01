import 'package:flutter/foundation.dart';

import 'fitgrid_plus_column.dart';

/// Abstract contract for data sources feeding [FitGridPlus].
///
/// Supports client-side in-memory collections as well as remote/server-side pageable sources.
abstract class FitGridPlusDataSource with ChangeNotifier {
  /// Column definitions for the grid.
  List<FitGridPlusColumn> get columns;

  /// Total count of rows across all pages (or currently loaded rows).
  int get totalRowCount;

  /// Fetches rows to be displayed in the grid.
  Future<List<Map<String, dynamic>>> fetchRows();

  /// Retrieves a lightweight JSON sample of rows.
  Future<List<Map<String, dynamic>>> getSampleData({int limit = 5});
}

/// In-memory client-side data source for [FitGridPlus].
class LocalFitGridPlusDataSource extends FitGridPlusDataSource {
  @override
  final List<FitGridPlusColumn> columns;
  List<Map<String, dynamic>> _data;

  LocalFitGridPlusDataSource({
    required this.columns,
    required List<Map<String, dynamic>> initialData,
  }) : _data = List<Map<String, dynamic>>.from(initialData);

  @override
  int get totalRowCount => _data.length;

  /// Direct access to underlying data maps.
  List<Map<String, dynamic>> get data => List.unmodifiable(_data);

  /// Updates or replaces the local dataset and notifies listeners.
  void setData(List<Map<String, dynamic>> newData) {
    _data = List<Map<String, dynamic>>.from(newData);
    notifyListeners();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRows() async {
    return _data;
  }

  @override
  Future<List<Map<String, dynamic>>> getSampleData({int limit = 5}) async {
    return _data.take(limit).toList();
  }
}

/// Dynamic page fetch function signature.
typedef FitGridPlusPaginationFetch = Future<List<Map<String, dynamic>>> Function({
  required int page,
  required int pageSize,
  String? sortColumn,
  bool descending,
  String? searchQuery,
});

/// Server-side / partial data lazy pagination data source for [FitGridPlus].
class LazyFitGridPlusDataSource extends FitGridPlusDataSource {
  @override
  final List<FitGridPlusColumn> columns;

  /// Callback invoked when a page of data, sorting, or filtering is requested.
  final FitGridPlusPaginationFetch fetch;

  /// Optional function returning total count of records across the entire dataset.
  final int Function()? totalRowCountGetter;

  /// Optional sample data.
  final List<Map<String, dynamic>>? sampleData;

  LazyFitGridPlusDataSource({
    required this.columns,
    required this.fetch,
    this.totalRowCountGetter,
    this.sampleData,
  });

  @override
  int get totalRowCount => totalRowCountGetter?.call() ?? 0;

  @override
  Future<List<Map<String, dynamic>>> fetchRows() async {
    return fetch(page: 1, pageSize: 100);
  }

  @override
  Future<List<Map<String, dynamic>>> getSampleData({int limit = 5}) async {
    if (sampleData != null && sampleData!.isNotEmpty) {
      return sampleData!.take(limit).toList();
    }
    try {
      final initialRes = await fetch(page: 1, pageSize: limit);
      return initialRes.take(limit).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
