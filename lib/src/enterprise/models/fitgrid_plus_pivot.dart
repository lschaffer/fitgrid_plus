import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../core/fitgrid_table.dart';
import 'fitgrid_plus_column.dart';

/// Aggregation functions supported in Pivot mode.
enum FitGridPlusPivotAggregation {
  sum,
  count,
  average,
  min,
  max;

  FitGridAggregation toFitGrid() {
    switch (this) {
      case FitGridPlusPivotAggregation.sum:
        return FitGridAggregation.sum;
      case FitGridPlusPivotAggregation.count:
        return FitGridAggregation.count;
      case FitGridPlusPivotAggregation.average:
        return FitGridAggregation.average;
      case FitGridPlusPivotAggregation.min:
        return FitGridAggregation.min;
      case FitGridPlusPivotAggregation.max:
        return FitGridAggregation.max;
    }
  }

  static FitGridPlusPivotAggregation fromString(String? value) {
    if (value == null) return FitGridPlusPivotAggregation.sum;
    switch (value.toLowerCase().trim()) {
      case 'avg':
      case 'average':
        return FitGridPlusPivotAggregation.average;
      case 'count':
        return FitGridPlusPivotAggregation.count;
      case 'min':
        return FitGridPlusPivotAggregation.min;
      case 'max':
        return FitGridPlusPivotAggregation.max;
      case 'sum':
      default:
        return FitGridPlusPivotAggregation.sum;
    }
  }

  String get displayName {
    switch (this) {
      case FitGridPlusPivotAggregation.sum:
        return 'Sum';
      case FitGridPlusPivotAggregation.count:
        return 'Count';
      case FitGridPlusPivotAggregation.average:
        return 'Average';
      case FitGridPlusPivotAggregation.min:
        return 'Min';
      case FitGridPlusPivotAggregation.max:
        return 'Max';
    }
  }
}

/// Pivot chart visualization types.
enum FitGridPlusPivotChartType {
  groupedBar,
  column,
  line,
  pie;

  static FitGridPlusPivotChartType fromString(String? value) {
    if (value == null) return FitGridPlusPivotChartType.groupedBar;
    switch (value.toLowerCase().trim()) {
      case 'column':
      case 'bar':
        return FitGridPlusPivotChartType.column;
      case 'line':
        return FitGridPlusPivotChartType.line;
      case 'pie':
      case 'donut':
        return FitGridPlusPivotChartType.pie;
      case 'groupedbar':
      default:
        return FitGridPlusPivotChartType.groupedBar;
    }
  }

  String get displayName {
    switch (this) {
      case FitGridPlusPivotChartType.groupedBar:
        return 'Grouped Bar';
      case FitGridPlusPivotChartType.column:
        return 'Column Bar';
      case FitGridPlusPivotChartType.line:
        return 'Line Trend';
      case FitGridPlusPivotChartType.pie:
        return 'Pie Chart';
    }
  }
}

/// A dimension or category field available for pivoting.
@immutable
class FitGridPlusPivotField {
  const FitGridPlusPivotField({
    required this.id,
    required this.label,
    this.type,
  });

  final String id;
  final String label;
  final FitGridPlusColumnType? type;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label,
    if (type != null) 'type': type!.name,
  };

  factory FitGridPlusPivotField.fromJson(Map<String, dynamic> json) {
    return FitGridPlusPivotField(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}

/// A value / measure field to aggregate in the pivot table.
@immutable
class FitGridPlusPivotValueField {
  const FitGridPlusPivotValueField({
    required this.columnId,
    this.aggregation = FitGridPlusPivotAggregation.sum,
    this.label,
    this.format,
  });

  final String columnId;
  final FitGridPlusPivotAggregation aggregation;
  final String? label;
  final String Function(num value)? format;

  String effectiveLabel(String fallbackColumnLabel) {
    if (label != null && label!.trim().isNotEmpty) return label!;
    return '$fallbackColumnLabel (${aggregation.displayName})';
  }

  FitGridPlusPivotValueField copyWith({
    String? columnId,
    FitGridPlusPivotAggregation? aggregation,
    String? label,
    String Function(num value)? format,
  }) {
    return FitGridPlusPivotValueField(
      columnId: columnId ?? this.columnId,
      aggregation: aggregation ?? this.aggregation,
      label: label ?? this.label,
      format: format ?? this.format,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'columnId': columnId,
    'aggregation': aggregation.name,
    if (label != null) 'label': label,
  };

  factory FitGridPlusPivotValueField.fromJson(Map<String, dynamic> json) {
    return FitGridPlusPivotValueField(
      columnId: json['columnId'] as String? ?? json['column'] as String? ?? '',
      aggregation: FitGridPlusPivotAggregation.fromString(
        json['aggregation'] as String? ?? json['type'] as String?,
      ),
      label: json['label'] as String?,
    );
  }
}

/// Backward compatibility alias for [FitGridPlusPivotValueField].
typedef FitGridPlusPivotValueConfig = FitGridPlusPivotValueField;

/// Full configuration for an active pivot transformation.
@immutable
class FitGridPlusPivotConfig {
  const FitGridPlusPivotConfig({
    List<String>? rowFieldIds,
    List<String>? rowFields,
    List<String>? columnFieldIds,
    List<String>? columnFields,
    List<FitGridPlusPivotValueField>? values,
    List<FitGridPlusPivotValueField>? dataFields,
    this.showColumnTotals = true,
    this.showRowTotals = true,
    this.showChart = false,
    this.chartType = FitGridPlusPivotChartType.groupedBar,
    this.groupByRows = true,
  })  : rowFieldIds = rowFieldIds ?? rowFields ?? const <String>[],
        columnFieldIds = columnFieldIds ?? columnFields ?? const <String>[],
        values = values ?? dataFields ?? const <FitGridPlusPivotValueField>[];

  final List<String> rowFieldIds;
  final List<String> columnFieldIds;
  final List<FitGridPlusPivotValueField> values;
  final bool showColumnTotals;
  final bool showRowTotals;
  final bool showChart;
  final FitGridPlusPivotChartType chartType;

  /// Whether to hierarchically group rows in tree format when multiple row dimensions are selected.
  final bool groupByRows;

  /// Convenience aliases
  List<String> get rowFields => rowFieldIds;
  List<String> get columnFields => columnFieldIds;
  List<FitGridPlusPivotValueField> get dataFields => values;

  FitGridPlusPivotConfig copyWith({
    List<String>? rowFieldIds,
    List<String>? columnFieldIds,
    List<FitGridPlusPivotValueField>? values,
    bool? showColumnTotals,
    bool? showRowTotals,
    bool? showChart,
    FitGridPlusPivotChartType? chartType,
    bool? groupByRows,
  }) {
    return FitGridPlusPivotConfig(
      rowFieldIds: rowFieldIds ?? this.rowFieldIds,
      columnFieldIds: columnFieldIds ?? this.columnFieldIds,
      values: values ?? this.values,
      showColumnTotals: showColumnTotals ?? this.showColumnTotals,
      showRowTotals: showRowTotals ?? this.showRowTotals,
      showChart: showChart ?? this.showChart,
      chartType: chartType ?? this.chartType,
      groupByRows: groupByRows ?? this.groupByRows,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'rowFieldIds': rowFieldIds,
    'columnFieldIds': columnFieldIds,
    'values': values.map((v) => v.toJson()).toList(),
    'showColumnTotals': showColumnTotals,
    'showRowTotals': showRowTotals,
    'showChart': showChart,
    'chartType': chartType.name,
    'groupByRows': groupByRows,
  };

  factory FitGridPlusPivotConfig.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as List<dynamic>? ?? const [];
    return FitGridPlusPivotConfig(
      rowFieldIds:
          (json['rowFieldIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['rows'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      columnFieldIds:
          (json['columnFieldIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['columns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      values: rawValues
          .whereType<Map<String, dynamic>>()
          .map(FitGridPlusPivotValueField.fromJson)
          .toList(),
      showColumnTotals: json['showColumnTotals'] as bool? ?? true,
      showRowTotals: json['showRowTotals'] as bool? ?? true,
      showChart: json['showChart'] as bool? ?? false,
      chartType: FitGridPlusPivotChartType.fromString(
        json['chartType'] as String?,
      ),
      groupByRows: json['groupByRows'] as bool? ?? true,
    );
  }
}

/// Data structure feeding the pivot side-panel chart visualization.
@immutable
class FitGridPlusPivotChartData {
  const FitGridPlusPivotChartData({
    required this.categories,
    required this.seriesNames,
    required this.values,
  });

  final List<String> categories;
  final List<String> seriesNames;
  final List<List<num>> values;

  bool get isEmpty => categories.isEmpty || seriesNames.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Result of a pivot transformation.
class FitGridPlusPivotResult {
  const FitGridPlusPivotResult({
    required this.rows,
    required this.columns,
    this.columnGroups = const [],
    this.chartData,
    this.rawPivot,
  });

  final List<Map<String, dynamic>> rows;
  final List<FitGridPlusColumn> columns;
  final List<FitGridColumnGroup> columnGroups;
  final FitGridPlusPivotChartData? chartData;
  final FitGridPivotResult? rawPivot;
}

/// Engine executing the pivot transformation on tabular data.
class FitGridPlusPivotEngine {
  const FitGridPlusPivotEngine._();

  /// Computes a pivot view from source [rows], [columns], and pivot [config].
  static FitGridPlusPivotResult execute({
    required List<Map<String, dynamic>> rows,
    required List<FitGridPlusColumn> columns,
    required FitGridPlusPivotConfig config,
  }) {
    if (config.rowFieldIds.isEmpty && config.columnFieldIds.isEmpty) {
      throw ArgumentError(
        'Pivot configuration must specify at least one row or column dimension.',
      );
    }

    FitGridPlusColumn? findCol(String id) {
      return columns.where((c) => c.field == id).firstOrNull;
    }

    // 1. Build row dimensions
    final rowDimensions = <FitGridPivotDimension<Map<String, dynamic>>>[
      for (final id in config.rowFieldIds) ...[
        () {
          final col = findCol(id);
          final label = col?.title ?? id;
          return FitGridPivotDimension<Map<String, dynamic>>(
            id: id,
            label: label,
            keyOf: (row) => row[id]?.toString() ?? '(blank)',
          );
        }(),
      ],
    ];

    // 2. Build column dimension (composite if multiple column fields)
    FitGridPivotDimension<Map<String, dynamic>>? colDimension;
    if (config.columnFieldIds.isNotEmpty) {
      final compId = config.columnFieldIds.join('__');
      final compLabel = config.columnFieldIds
          .map((id) => findCol(id)?.title ?? id)
          .join(' / ');
      colDimension = FitGridPivotDimension<Map<String, dynamic>>(
        id: compId,
        label: compLabel,
        keyOf: (row) => config.columnFieldIds
            .map((id) => row[id]?.toString() ?? '(blank)')
            .join(' / '),
      );
    }

    // 3. Build value metrics
    final valueDimensions = <FitGridPivotValue<Map<String, dynamic>>>[
      for (final v in config.values) ...[
        () {
          final col = findCol(v.columnId);
          final title = col?.title ?? v.columnId;
          final effectiveLbl = v.effectiveLabel(title);

          return FitGridPivotValue<Map<String, dynamic>>(
            id: v.columnId,
            label: effectiveLbl,
            aggregation: v.aggregation.toFitGrid(),
            valueOf: (row) {
              final raw = row[v.columnId];
              if (raw is num) return raw;
              if (raw == null) return null;
              return num.tryParse(
                raw.toString().replaceAll(RegExp(r'[^0-9.-]'), ''),
              );
            },
            format: v.format,
          );
        }(),
      ],
    ];

    // 4. Compute fitGridPivot from core engine
    final pivotResult = fitGridPivot<Map<String, dynamic>>(
      rows,
      rows: rowDimensions,
      columns: colDimension,
      values: valueDimensions,
      columnTotals: config.showColumnTotals,
    );

    // 5. Convert pivotResult to Map<String, dynamic> rows
    final pivotedRows = <Map<String, dynamic>>[];
    for (final pr in pivotResult.rows) {
      final rowMap = <String, dynamic>{};
      for (var i = 0; i < rowDimensions.length; i++) {
        rowMap[rowDimensions[i].id] = pr.keys[i]?.toString() ?? '(blank)';
      }
      for (final cell in pr.cells.entries) {
        rowMap[cell.key] = cell.value;
      }
      pivotedRows.add(rowMap);
    }

    // 6. Build column groups (banded headers) & new FitGridPlusColumns
    final columnGroups = <FitGridColumnGroup>[];
    final subTitleByColId = <String, String>{};

    if (colDimension != null) {
      final groupsMap = <String, List<String>>{};
      for (final col in pivotResult.columns.skip(rowDimensions.length)) {
        if (col.id.startsWith('total/')) {
          final valId = col.id.substring('total/'.length);
          final valDim = valueDimensions
              .where((v) => v.id == valId)
              .firstOrNull;
          final subTitle = valDim?.label ?? valId;
          groupsMap.putIfAbsent('Grand Total', () => []).add(col.id);
          subTitleByColId[col.id] = subTitle;
        } else {
          final prefix = '${colDimension.id}=';
          if (col.id.startsWith(prefix)) {
            final rest = col.id.substring(prefix.length);
            final slashIdx = rest.lastIndexOf('/');
            if (slashIdx != -1) {
              final headingLabel = rest.substring(0, slashIdx);
              final valId = rest.substring(slashIdx + 1);
              final valDim = valueDimensions
                  .where((v) => v.id == valId)
                  .firstOrNull;
              final subTitle = valDim?.label ?? valId;
              groupsMap.putIfAbsent(headingLabel, () => []).add(col.id);
              subTitleByColId[col.id] = subTitle;
            }
          }
        }
      }

      for (final entry in groupsMap.entries) {
        columnGroups.add(
          FitGridColumnGroup(
            id: entry.key,
            label: entry.key,
            columnIds: entry.value,
          ),
        );
      }
    }

    final pivotedColumns = <FitGridPlusColumn>[];

    // Row dimension columns (ungrouped, span full double-height header)
    for (var i = 0; i < rowDimensions.length; i++) {
      pivotedColumns.add(
        FitGridPlusColumn(
          field: rowDimensions[i].id,
          title: rowDimensions[i].label,
          width: 140,
          type: FitGridPlusColumnType.text,
        ),
      );
    }

    // Measure / value columns (nested under their column group band)
    for (final col in pivotResult.columns.skip(rowDimensions.length)) {
      final displayTitle = subTitleByColId[col.id] ?? col.label;
      pivotedColumns.add(
        FitGridPlusColumn(
          field: col.id,
          title: displayTitle,
          width: 140,
          type: FitGridPlusColumnType.number,
          aggregateType: FitGridPlusAggregateType.sum,
          cellBuilder: (context, row, rowIndex) {
            final val = row[col.id];
            final isEmpty = val == null || val.toString().isEmpty;
            return Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                isEmpty
                    ? '—'
                    : (val is num
                          ? NumberFormat('#,##0.##').format(val)
                          : val.toString()),
                style: TextStyle(
                  fontSize: 12,
                  color: isEmpty ? const Color(0xFFBDBDBD) : null,
                  fontStyle: isEmpty ? FontStyle.italic : null,
                ),
              ),
            );
          },
        ),
      );
    }

    // 7. Generate chart data
    final categories = <String>[
      for (final pr in pivotResult.rows)
        pr.keys.map((k) => k?.toString() ?? '').join(' - '),
    ];

    final measureColumns = pivotResult.columns
        .skip(rowDimensions.length)
        .toList();
    final seriesNames = <String>[for (final c in measureColumns) c.label];
    final matrix = <List<num>>[
      for (final c in measureColumns)
        <num>[
          for (final pr in pivotResult.rows)
            pr.cells[c.id] ?? 0,
        ],
    ];

    final chartData = FitGridPlusPivotChartData(
      categories: categories,
      seriesNames: seriesNames,
      values: matrix,
    );

    return FitGridPlusPivotResult(
      rows: pivotedRows,
      columns: pivotedColumns,
      columnGroups: columnGroups,
      chartData: chartData,
      rawPivot: pivotResult,
    );
  }
}
