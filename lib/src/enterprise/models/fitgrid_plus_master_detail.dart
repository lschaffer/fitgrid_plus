import 'package:flutter/widgets.dart';

/// Signature for building a master-detail row widget given the parent row data and its index.
typedef FitGridPlusDetailRowBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic> row,
  int rowIndex,
);

/// Master-detail configuration options for [FitGridPlus].
class FitGridPlusMasterDetailOptions {
  /// Whether the master-detail feature is active and the expansion column is shown.
  final bool enabled;

  /// Builder callback for the detail panel beneath an expanded row.
  final FitGridPlusDetailRowBuilder detailBuilder;

  /// Default height of the detail panel when [detailHeight] is null. Defaults to 360.0.
  final double detailRowHeight;

  /// Optional dynamic height callback per row.
  final double Function(Map<String, dynamic> row, int rowIndex)? detailHeight;

  /// Function to derive a unique, stable key for each row.
  /// If null, defaults to `row['id'] ?? row`.
  final Object Function(Map<String, dynamic> row)? rowKey;

  /// If true, expanding a row will automatically collapse any other expanded rows (accordion mode).
  final bool autoCollapseOthers;

  /// Initial set of row keys that should be expanded on load.
  final Set<Object>? initiallyExpandedKeys;

  /// Optional callback when a row's expansion state changes.
  final void Function(Object rowKey, bool isExpanded)? onExpansionChanged;

  const FitGridPlusMasterDetailOptions({
    this.enabled = true,
    required this.detailBuilder,
    this.detailRowHeight = 360.0,
    this.detailHeight,
    this.rowKey,
    this.autoCollapseOthers = false,
    this.initiallyExpandedKeys,
    this.onExpansionChanged,
  });

  /// Creates a copy of this options object with the given fields replaced.
  FitGridPlusMasterDetailOptions copyWith({
    bool? enabled,
    FitGridPlusDetailRowBuilder? detailBuilder,
    double? detailRowHeight,
    double Function(Map<String, dynamic> row, int rowIndex)? detailHeight,
    Object Function(Map<String, dynamic> row)? rowKey,
    bool? autoCollapseOthers,
    Set<Object>? initiallyExpandedKeys,
    void Function(Object rowKey, bool isExpanded)? onExpansionChanged,
  }) {
    return FitGridPlusMasterDetailOptions(
      enabled: enabled ?? this.enabled,
      detailBuilder: detailBuilder ?? this.detailBuilder,
      detailRowHeight: detailRowHeight ?? this.detailRowHeight,
      detailHeight: detailHeight ?? this.detailHeight,
      rowKey: rowKey ?? this.rowKey,
      autoCollapseOthers: autoCollapseOthers ?? this.autoCollapseOthers,
      initiallyExpandedKeys:
          initiallyExpandedKeys ?? this.initiallyExpandedKeys,
      onExpansionChanged: onExpansionChanged ?? this.onExpansionChanged,
    );
  }
}
