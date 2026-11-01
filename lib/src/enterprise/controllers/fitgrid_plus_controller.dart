import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/fitgrid_table.dart';
import '../config/fitgrid_plus_dynamic_storage.dart';
import '../data/excel_table_parser.dart';
import '../data/fitgrid_plus_data_cleaner.dart';
import '../models/fitgrid_plus_column.dart';
import '../models/fitgrid_plus_conditional_format.dart';
import '../models/fitgrid_plus_context_action.dart';
import '../models/fitgrid_plus_data_auditor.dart';
import '../models/fitgrid_plus_data_source.dart';
import '../models/fitgrid_plus_dynamic_datasource.dart';
import '../models/fitgrid_plus_editing_options.dart';
import '../models/fitgrid_plus_master_detail.dart';
import '../models/fitgrid_plus_pivot.dart';
import '../models/fitgrid_plus_range_summary.dart';
import '../models/fitgrid_plus_view_mode.dart';
import '../widgets/fitgrid_plus_column_editor_dialog.dart';
import '../widgets/fitgrid_plus_columns_editor_dialog.dart';
import '../widgets/fitgrid_plus_data_auditor_dialog.dart';
import '../widgets/fitgrid_plus_excel_dialogs.dart';
import '../widgets/fitgrid_plus_form_dialog.dart';

/// Controller coordinating grid state, grouping, filtering, sorting,
/// column visibility, pivot aggregation, DevExtreme editing, and data export.
class FitGridPlusController extends ChangeNotifier {
  FitGridController<Map<String, dynamic>>? _fitController;
  FitGridPlusDataSource? _dataSource;
  List<FitGridPlusColumn> _columns = [];

  FitGridPlusDynamicDescriptor? _activeDynamicDatasource;
  FitGridPlusExcelWorkbook? _activeExcelWorkbook;

  /// Active dynamic datasource descriptor if currently bound to a dynamic dataset.
  FitGridPlusDynamicDescriptor? get activeDynamicDatasource =>
      _activeDynamicDatasource;

  /// Active Excel workbook if currently bound to an imported Excel dataset.
  FitGridPlusExcelWorkbook? get activeExcelWorkbook => _activeExcelWorkbook;

  List<String> _activeGrouping = [];
  final Map<String, Map<String, dynamic>> _activeFilters = {};
  String? _activeSortColumn;
  bool _isSortDescending = false;
  final Set<String> _hiddenFields = {};
  String _searchQuery = '';
  bool _showColumnFilterRow = true;
  bool _showGroupPanel = true;
  bool _isApplyingFilters = false;
  FitGridPlusViewMode _viewMode = FitGridPlusViewMode.grid;

  /// Current layout mode: [FitGridPlusViewMode.grid] (DataGrid) or [FitGridPlusViewMode.card] (card feed).
  FitGridPlusViewMode get viewMode => _viewMode;

  /// Sets the active view mode (grid or card).
  void setViewMode(FitGridPlusViewMode mode, {bool notify = true}) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    if (notify) {
      notifyListeners();
    }
  }

  /// Toggles between grid and card view modes.
  void toggleViewMode() {
    setViewMode(
      _viewMode == FitGridPlusViewMode.grid
          ? FitGridPlusViewMode.card
          : FitGridPlusViewMode.grid,
    );
  }

  FitGridPlusContextMenuConfiguration _contextMenuConfig =
      const FitGridPlusContextMenuConfiguration();

  /// Configuration for right-click and long-press contextual menus.
  FitGridPlusContextMenuConfiguration get contextMenuConfig =>
      _contextMenuConfig;

  /// Sets the contextual menu configuration.
  void setContextMenuConfig(
    FitGridPlusContextMenuConfiguration config, {
    bool notify = true,
  }) {
    _contextMenuConfig = config;
    if (notify) {
      notifyListeners();
    }
  }

  /// Filters the grid to records matching [value] in [field].
  void filterSimilar({required String field, required dynamic value}) {
    setFilter(field, operator: 'equals', value: value);
  }

  FitGridPlusEditingOptions _editingOptions = const FitGridPlusEditingOptions();
  int? _editingRowIndex;
  Map<String, dynamic>? _draftRow;
  bool _isAddingRow = false;
  final Map<String, String> _validationErrors = {};

  /// Empty placeholder row shown in the grid while adding in row mode.
  Map<String, dynamic>? _pendingNewRow;

  /// Removes the row-mode placeholder row (if any) from the grid data.
  int _discardPendingRow() {
    final pending = _pendingNewRow;
    _pendingNewRow = null;
    if (pending == null || _fitController == null) return -1;
    final viewIdx = _fitController!.data.view.indexOf(pending);
    final allRows = List<Map<String, dynamic>>.from(_fitController!.data.rows)
      ..remove(pending);
    _fitController!.data.rows = allRows;
    return viewIdx;
  }

  /// Current editing options configured for this grid.
  FitGridPlusEditingOptions get editingOptions => _editingOptions;
  set editingOptions(FitGridPlusEditingOptions options) =>
      setEditingOptions(options);

  /// Index of the row currently being edited in row/form mode, or null.
  int? get editingRowIndex => _editingRowIndex;

  /// In-progress draft values for the currently edited or added row.
  Map<String, dynamic>? get draftRow => _draftRow;

  /// Whether a brand-new row is currently being added.
  bool get isAddingRow => _isAddingRow;

  /// Whether any row is currently in an active edit or add session.
  bool get isEditingRow => _editingRowIndex != null || _isAddingRow;

  /// Validation error messages keyed by column field name.
  Map<String, String> get validationErrors =>
      Map.unmodifiable(_validationErrors);

  /// Updates the editing options and notifies listeners.
  void setEditingOptions(
    FitGridPlusEditingOptions options, {
    bool notify = true,
  }) {
    if (_editingOptions == options) return;
    if (options.mode != _editingOptions.mode && isEditingRow) {
      _discardPendingRow();
      _editingRowIndex = null;
      _isAddingRow = false;
      _draftRow = null;
      _validationErrors.clear();
    }
    _editingOptions = options;
    if (notify) {
      notifyListeners();
    }
  }

  final List<FitGridPlusEditEvent> _editEvents = [];

  /// Historical log of editing events.
  List<FitGridPlusEditEvent> get editEvents => List.unmodifiable(_editEvents);

  /// Records an editing event in the event history.
  void logEditEvent(FitGridPlusEditEvent event) {
    _editEvents.add(event);
    if (_editEvents.length > 500) {
      _editEvents.removeAt(0);
    }
    notifyListeners();
  }

  /// Clears all recorded editing events.
  void clearEditEvents() {
    _editEvents.clear();
    notifyListeners();
  }

  final List<FitGridPlusConditionalFormat> _conditionalFormats = [];

  /// Active conditional formatting rules.
  List<FitGridPlusConditionalFormat> get conditionalFormats =>
      List.unmodifiable(_conditionalFormats);

  /// Adds or updates a conditional formatting rule and updates the grid.
  void addConditionalFormat(
    FitGridPlusConditionalFormat format, {
    bool notify = true,
  }) {
    _conditionalFormats.removeWhere((f) => f.id == format.id);
    _conditionalFormats.add(format);
    _syncEffectiveColumns();
    if (notify) {
      notifyListeners();
    }
  }

  /// Removes a conditional formatting rule by [id].
  void removeConditionalFormat(String id) {
    _conditionalFormats.removeWhere((f) => f.id == id);
    _syncEffectiveColumns();
    notifyListeners();
  }

  /// Clears all conditional formatting rules or rules matching [field].
  void clearConditionalFormats([String? field]) {
    if (field != null) {
      _conditionalFormats.removeWhere((f) => f.field == field);
    } else {
      _conditionalFormats.clear();
    }
    _syncEffectiveColumns();
    notifyListeners();
  }

  /// Resolves row background color for conditional formatting.
  Color? resolveRowColor(Map<String, dynamic> row, int rowIndex) {
    for (final fmt in _conditionalFormats) {
      if (fmt.type == FitGridPlusFormatType.highlight &&
          fmt.applyToRow &&
          fmt.backgroundColor != null) {
        final val = fmt.field == '*' ? row : row[fmt.field];
        if (fmt.matches(val, row)) {
          return fmt.backgroundColor;
        }
      }
    }
    return null;
  }

  /// Builds a [FitGridColumn] from a [FitGridPlusColumn], applying active conditional formats.
  FitGridColumn<Map<String, dynamic>> buildFitGridColumn(
    FitGridPlusColumn col,
  ) {
    var effectiveCol = col;
    final fieldFormats = _conditionalFormats
        .where((f) => f.field == col.field)
        .toList();
    if (fieldFormats.isNotEmpty) {
      final barFormat = fieldFormats
          .where((f) => f.type == FitGridPlusFormatType.dataBar)
          .firstOrNull;
      final highlightFormats = fieldFormats
          .where((f) => f.type == FitGridPlusFormatType.highlight)
          .toList();
      final colorScaleFormat = fieldFormats
          .where((f) => f.type == FitGridPlusFormatType.colorScale)
          .firstOrNull;

      FitGridCellVisual<Map<String, dynamic>>? visual = col.visual;
      if (visual == null && barFormat != null) {
        visual = FitGridCellVisual.bar(
          (row) {
            final v = row[col.field];
            if (v is num) return v;
            if (v != null) return num.tryParse(v.toString());
            return null;
          },
          min: barFormat.min,
          max: barFormat.max,
          color: barFormat.positiveColor,
          negativeColor: barFormat.negativeColor,
          showText: barFormat.showText,
        );
      }

      TextStyle? Function(dynamic value, Map<String, dynamic> row)? cellStyle =
          col.cellStyle;
      if (highlightFormats.isNotEmpty || colorScaleFormat != null) {
        final existingStyle = cellStyle;
        cellStyle = (val, row) {
          TextStyle? base = existingStyle?.call(val, row);
          for (final h in highlightFormats) {
            if (h.matches(val, row)) {
              base = (base ?? const TextStyle()).copyWith(
                color: h.textColor,
                fontWeight: h.fontWeight,
                backgroundColor: h.applyToRow ? null : h.backgroundColor,
              );
            }
          }
          if (colorScaleFormat != null && val is num) {
            final min = colorScaleFormat.min ?? 0;
            final max = colorScaleFormat.max ?? 100;
            final interpolated = colorScaleFormat.interpolateColor(
              val,
              min,
              max,
            );
            if (interpolated != null) {
              base = (base ?? const TextStyle()).copyWith(color: interpolated);
            }
          }
          return base;
        };
      }

      effectiveCol = col.copyWith(visual: visual, cellStyle: cellStyle);
    }

    return effectiveCol.toFitGridColumn();
  }

  void _syncEffectiveColumns() {
    if (_fitController == null) return;
    final hidden = hiddenColumns.toSet();
    _fitController!.columns.columns = _columns.map((c) {
      final col = buildFitGridColumn(c);
      if (hidden.contains(c.field)) {
        return col.copyWith(visible: false);
      }
      return col;
    }).toList();
  }

  /// Starts adding a new row, initializing draft values with column defaults or [initialValues].
  void startAdd([Map<String, dynamic>? initialValues]) {
    if (_activeDynamicDatasource?.isReadonly == true) return;
    _discardPendingRow();
    _editingRowIndex = null;
    _isAddingRow = true;
    _validationErrors.clear();
    _draftRow = <String, dynamic>{};
    for (final col in _columns) {
      if (initialValues != null && initialValues.containsKey(col.field)) {
        _draftRow![col.field] = initialValues[col.field];
      } else {
        _draftRow![col.field] = null;
      }
    }

    // Row mode: show an empty record inline at the configured position.
    if (_editingOptions.mode == FitGridPlusEditMode.row &&
        _fitController != null) {
      final placeholder = Map<String, dynamic>.from(_draftRow!);
      final allRows = List<Map<String, dynamic>>.from(
        _fitController!.data.rows,
      );
      if (_editingOptions.insertRowPosition ==
          FitGridPlusInsertRowPosition.top) {
        allRows.insert(0, placeholder);
      } else {
        allRows.add(placeholder);
      }
      _fitController!.data.rows = allRows;
      _pendingNewRow = placeholder;
      final idx = _fitController!.data.view.indexOf(placeholder);
      _editingRowIndex = idx >= 0 ? idx : null;
    }

    logEditEvent(
      FitGridPlusEditEvent(
        action: 'startAdd',
        message: 'Started adding a new record',
        data: initialValues,
      ),
    );
    notifyListeners();
  }

  /// Starts editing an existing row at [rowIndex] in row or form mode.
  void startEditingRow(int rowIndex) => startEdit(rowIndex);

  void startEdit(int rowIndex) {
    if (_activeDynamicDatasource?.isReadonly == true) return;
    if (_fitController == null) return;
    final removedAt = _discardPendingRow();
    if (removedAt >= 0 && removedAt < rowIndex) rowIndex--;
    final rows = _fitController!.data.view;
    if (rowIndex < 0 || rowIndex >= rows.length) return;
    _editingRowIndex = rowIndex;
    _isAddingRow = false;
    _validationErrors.clear();
    final row = rows[rowIndex];
    _draftRow = Map<String, dynamic>.from(row);
    final idVal = row['OrderID'] ?? row['id'] ?? row['ID'] ?? '#$rowIndex';
    logEditEvent(
      FitGridPlusEditEvent(
        action: 'startEdit',
        rowIndex: rowIndex,
        message: 'Started editing row #$rowIndex ($idVal)',
        data: row,
      ),
    );
    notifyListeners();
  }

  /// Opens modal popup [FitGridPlusFormDialog] to add or edit a row.
  Future<bool?> showEditDialog(
    BuildContext context, {
    int? rowIndex,
    Map<String, dynamic>? initialValues,
    String? title,
  }) {
    if (_activeDynamicDatasource?.isReadonly == true) {
      return Future.value(false);
    }
    if (rowIndex != null) {
      startEdit(rowIndex);
    } else {
      startAdd(initialValues);
    }
    return FitGridPlusFormDialog.show(context, controller: this, title: title);
  }

  /// Updates a single column's value in the active edit draft.
  void updateDraftValue(String column, dynamic value) {
    if (_draftRow == null) return;
    final oldVal = _draftRow![column];
    _draftRow![column] = value;
    final col = _columns.where((c) => c.field == column).firstOrNull;
    if (col != null) {
      final err = col.validate(value);
      if (err != null) {
        _validationErrors[column] = err;
      } else {
        _validationErrors.remove(column);
      }
      col.onChanged?.call(value, _draftRow!);
    }
    logEditEvent(
      FitGridPlusEditEvent(
        action: 'change',
        rowIndex: _editingRowIndex,
        field: column,
        oldValue: oldVal,
        newValue: value,
        message:
            'Updated field "$column": ${oldVal ?? "null"} → ${value ?? "null"}',
      ),
    );
    notifyListeners();
  }

  /// Cancels active editing or adding session and discards draft changes.
  void cancelEdit() {
    final prevIdx = _editingRowIndex;
    final wasAdding = _isAddingRow;
    _discardPendingRow();
    _editingRowIndex = null;
    _isAddingRow = false;
    _draftRow = null;
    _validationErrors.clear();
    logEditEvent(
      FitGridPlusEditEvent(
        action: 'cancel',
        rowIndex: prevIdx,
        message: wasAdding
            ? 'Cancelled adding new record'
            : 'Cancelled editing row #${prevIdx ?? "unknown"}',
      ),
    );
    notifyListeners();
  }

  /// Validates and saves active edit or added row.
  Future<String?> saveEdit() async {
    if (_activeDynamicDatasource?.isReadonly == true) {
      return 'Table is read-only';
    }
    if (_draftRow == null || _fitController == null) {
      return null;
    }

    // 1. Column-level validation
    _validationErrors.clear();
    for (final col in _columns) {
      if (col.isEditable) {
        final err = col.validate(_draftRow![col.field]);
        if (err != null) {
          _validationErrors[col.field] = err;
        }
      }
    }
    if (_validationErrors.isNotEmpty) {
      final err = _validationErrors.values.first;
      logEditEvent(
        FitGridPlusEditEvent(
          action: 'error',
          rowIndex: _editingRowIndex,
          message: 'Validation failed: $err',
        ),
      );
      notifyListeners();
      return err;
    }

    final originalRow = _isAddingRow
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
            _fitController!.data.view[_editingRowIndex!],
          );

    // 2. beforeSave lifecycle hook
    if (_editingOptions.beforeSave != null) {
      final err = await _editingOptions.beforeSave!(originalRow, _draftRow!);
      if (err != null) {
        logEditEvent(
          FitGridPlusEditEvent(
            action: 'error',
            rowIndex: _editingRowIndex,
            message: 'beforeSave rejected: $err',
          ),
        );
        notifyListeners();
        return err;
      }
    }

    // 3. Commit modified fields via options.commit
    if (_editingOptions.commit != null) {
      for (final entry in _draftRow!.entries) {
        if (_isAddingRow || entry.value != originalRow[entry.key]) {
          _editingOptions.commit!(entry.key, entry.value);
        }
      }
    }

    final isAdding = _isAddingRow;
    final targetIndex = _editingRowIndex;

    // 4. Update data in FitGridController and DataSource
    final allRows = List<Map<String, dynamic>>.from(_fitController!.data.rows);
    if (_isAddingRow) {
      final newRow = Map<String, dynamic>.from(_draftRow!);
      final pendingIdx = _pendingNewRow == null
          ? -1
          : allRows.indexOf(_pendingNewRow!);
      if (pendingIdx >= 0) {
        allRows[pendingIdx] = newRow;
      } else if (_editingOptions.insertRowPosition ==
          FitGridPlusInsertRowPosition.bottom) {
        allRows.add(newRow);
      } else {
        allRows.insert(0, newRow);
      }
      _pendingNewRow = null;
    } else {
      final targetRow = _fitController!.data.view[_editingRowIndex!];
      final globalIndex = allRows.indexOf(targetRow);
      if (globalIndex != -1) {
        allRows[globalIndex] = Map<String, dynamic>.from(_draftRow!);
      }
    }
    _fitController!.data.rows = allRows;
    if (_dataSource is LocalFitGridPlusDataSource) {
      (_dataSource as LocalFitGridPlusDataSource).setData(allRows);
    }
    if (_activeDynamicDatasource != null &&
        !_activeDynamicDatasource!.isReadonly) {
      FitGridPlusDynamicStorage.updateDataRows(
        _activeDynamicDatasource!.name,
        allRows,
      );
    }

    final savedRow = Map<String, dynamic>.from(_draftRow!);

    _editingRowIndex = null;
    _isAddingRow = false;
    _draftRow = null;
    _validationErrors.clear();

    logEditEvent(
      FitGridPlusEditEvent(
        action: 'save',
        rowIndex: targetIndex,
        message: isAdding
            ? 'Successfully added new record'
            : 'Successfully saved row #${targetIndex ?? 0}',
        data: savedRow,
      ),
    );

    // 5. afterSave lifecycle hook
    _editingOptions.afterSave?.call(savedRow);

    notifyListeners();
    return null;
  }

  /// Deletes a row at [rowIndex] after running beforeDelete guard.
  Future<bool> deleteRow(int rowIndex) async {
    if (_activeDynamicDatasource?.isReadonly == true) return false;
    if (_fitController == null) return false;
    final viewRows = _fitController!.data.view;
    if (rowIndex < 0 || rowIndex >= viewRows.length) return false;

    final targetRow = viewRows[rowIndex];

    // 1. beforeDelete hook
    if (_editingOptions.beforeDelete != null) {
      final proceed = await _editingOptions.beforeDelete!(targetRow);
      if (!proceed) return false;
    }

    // 2. Remove row from dataset
    final allRows = List<Map<String, dynamic>>.from(_fitController!.data.rows);
    allRows.remove(targetRow);
    _fitController!.data.rows = allRows;
    if (_dataSource is LocalFitGridPlusDataSource) {
      (_dataSource as LocalFitGridPlusDataSource).setData(allRows);
    }
    if (_activeDynamicDatasource != null &&
        !_activeDynamicDatasource!.isReadonly) {
      FitGridPlusDynamicStorage.updateDataRows(
        _activeDynamicDatasource!.name,
        allRows,
      );
    }

    final idVal =
        targetRow['OrderID'] ??
        targetRow['id'] ??
        targetRow['ID'] ??
        '#$rowIndex';
    logEditEvent(
      FitGridPlusEditEvent(
        action: 'delete',
        rowIndex: rowIndex,
        message: 'Deleted row #$rowIndex ($idVal)',
        data: targetRow,
      ),
    );

    // 3. afterDelete hook
    _editingOptions.afterDelete?.call(targetRow);

    notifyListeners();
    return true;
  }

  /// Underlying FitGridController if attached.
  FitGridController<Map<String, dynamic>>? get fitController => _fitController;

  /// Grid columns defined for this DataGrid.
  List<FitGridPlusColumn> get columns => _columns;

  /// Active dataset rows.
  List<Map<String, dynamic>> get rows {
    if (_fitController != null) {
      return _fitController!.data.rows;
    } else if (_dataSource is LocalFitGridPlusDataSource) {
      return (_dataSource as LocalFitGridPlusDataSource).data;
    }
    return const [];
  }

  /// Active filtered and sorted view rows.
  List<Map<String, dynamic>> get viewRows {
    if (_fitController != null) {
      return _fitController!.data.view;
    } else if (_dataSource is LocalFitGridPlusDataSource) {
      return (_dataSource as LocalFitGridPlusDataSource).data;
    }
    return const [];
  }

  /// Active data source if attached.
  FitGridPlusDataSource? get dataSource => _dataSource;

  /// Currently active grouping fields (hierarchical).
  List<String> get activeGrouping => List.unmodifiable(_activeGrouping);

  /// Active column filters keyed by column field name.
  Map<String, Map<String, dynamic>> get activeFilters =>
      Map.unmodifiable(_activeFilters);

  /// Active sort column field name.
  String? get activeSortColumn => _activeSortColumn;

  /// Whether current sort is descending.
  bool get isSortDescending => _isSortDescending;

  /// Active global search query.
  String get searchQuery => _searchQuery;

  /// Whether inline column filter row is visible.
  bool get showColumnFilterRow => _showColumnFilterRow;
  set showColumnFilterRow(bool value) {
    if (_showColumnFilterRow == value) return;
    _showColumnFilterRow = value;
    notifyListeners();
  }

  /// Whether the top group panel is visible.
  bool get showGroupPanel => _showGroupPanel;
  set showGroupPanel(bool value) {
    if (_showGroupPanel == value) return;
    _showGroupPanel = value;
    notifyListeners();
  }

  /// Whether controller is attached to an active grid controller.
  bool get isAttached => _fitController != null;

  /// Current page number (1-based index).
  int get page => (_fitController?.pagination.pageIndex ?? 0) + 1;

  /// Total number of pages available.
  int get totalPage => _fitController?.pagination.pageCount ?? 1;

  /// Number of rows per page.
  int get pageSize => _fitController?.pagination.pageSize ?? 40;

  /// Whether pagination is currently active on the grid.
  bool get isPaginated => _fitController?.pagination.enabled ?? false;

  /// Navigates to a specific page number (1-based).
  void setPage(int page) {
    if (_fitController != null && _fitController!.pagination.enabled) {
      _fitController!.pagination.pageIndex = (page - 1).clamp(0, totalPage - 1);
      notifyListeners();
    }
  }

  /// Sets the number of rows displayed per page.
  void setPageSize(int size) {
    if (_fitController != null && _fitController!.pagination.enabled) {
      _fitController!.pagination.pageSize = size;
      notifyListeners();
    }
  }

  void _onFitControllerChanged() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    } else {
      notifyListeners();
    }
  }

  /// Attaches controller to rendered grid controller and data source.
  void attach({
    FitGridController<Map<String, dynamic>>? fitController,
    required List<FitGridPlusColumn> columns,
    required FitGridPlusDataSource dataSource,
    bool notify = false,
  }) {
    if (_fitController != null &&
        _fitController != fitController &&
        fitController != null) {
      _fitController!.data.removeListener(_onFitControllerChanged);
      _fitController!.columns.removeListener(_onFitControllerChanged);
      _fitController!.filter.removeListener(_onFitFilterChanged);
      _fitController!.range.removeListener(_onFitRangeChanged);
      _fitController!.details.removeListener(_onFitDetailsChanged);
    }
    _fitController =
        fitController ??
        _fitController ??
        FitGridController<Map<String, dynamic>>(
          columns: columns.map((c) => c.toFitGridColumn()).toList(),
          rows: dataSource is LocalFitGridPlusDataSource
              ? dataSource.data
              : const [],
        );
    _columns = columns;
    _dataSource = dataSource;

    // Column width overrides
    for (final col in _columns) {
      if (col.width != null &&
          col.width! > 0 &&
          !_fitController!.columns.isResized(col.field)) {
        _fitController!.columns.setWidth(col.field, col.width!);
      }
    }

    _fitController!.data.removeListener(_onFitControllerChanged);
    _fitController!.columns.removeListener(_onFitControllerChanged);
    _fitController!.filter.removeListener(_onFitFilterChanged);
    _fitController!.range.removeListener(_onFitRangeChanged);
    _fitController!.details.removeListener(_onFitDetailsChanged);
    _fitController!.data.addListener(_onFitControllerChanged);
    _fitController!.columns.addListener(_onFitControllerChanged);
    _fitController!.filter.addListener(_onFitFilterChanged);
    _fitController!.range.addListener(_onFitRangeChanged);
    _fitController!.details.addListener(_onFitDetailsChanged);

    if (_masterDetailOptions?.initiallyExpandedKeys != null) {
      for (final key in _masterDetailOptions!.initiallyExpandedKeys!) {
        _fitController!.details.setExpanded(key, true);
      }
      _previousExpandedKeys = Set<Object>.of(_fitController!.details.expanded);
    }

    if (_activeGrouping.isNotEmpty) {
      setGrouping(_activeGrouping, notify: false);
    }
    if (_activeSortColumn != null) {
      sort(_activeSortColumn!, descending: _isSortDescending, notify: false);
    }
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery, notify: false);
    }
    if (_hiddenFields.isNotEmpty) {
      for (final col in _columns) {
        if (_hiddenFields.contains(col.field)) {
          _fitController!.columns.setVisible(col.field, false);
        }
      }
    }

    if (notify) {
      notifyListeners();
    }
  }

  /// Loads dynamic datasource into the grid.
  void loadDynamicDatasource(
    FitGridPlusDynamicDescriptor descriptor,
    List<FitGridPlusColumn> columns,
    List<Map<String, dynamic>> rows,
  ) {
    _activeDynamicDatasource = descriptor;
    final effectiveColumns = descriptor.isReadonly
        ? columns
              .map((c) => c.copyWith(editable: false, enableEditingMode: false))
              .toList()
        : columns
              .map((c) => c.editable != null ? c : c.copyWith(editable: true))
              .toList();
    _columns = effectiveColumns;
    _dataSource = LocalFitGridPlusDataSource(
      columns: effectiveColumns,
      initialData: rows,
    );

    if (_fitController != null) {
      _fitController!.columns.columns = effectiveColumns
          .map((c) => c.toFitGridColumn())
          .toList();
      _fitController!.data.rows = rows;
    } else {
      _fitController = FitGridController<Map<String, dynamic>>(
        columns: effectiveColumns.map((c) => c.toFitGridColumn()).toList(),
        rows: rows,
      );
    }

    for (final col in _columns) {
      if (col.width != null && col.width! > 0) {
        _fitController!.columns.setWidth(col.field, col.width!);
      }
    }

    _discardPendingRow();
    _editingRowIndex = null;
    _isAddingRow = false;
    _draftRow = null;
    _validationErrors.clear();

    _activeGrouping.clear();
    _activeFilters.clear();
    _activeSortColumn = null;
    _searchQuery = '';
    _hiddenFields.clear();

    FitGridPlusDynamicStorage.setActiveDatasourceName(descriptor.name);
    notifyListeners();
  }

  /// Resets grid to empty dynamic state.
  void clearDynamicDatasource() {
    _discardPendingRow();
    _editingRowIndex = null;
    _isAddingRow = false;
    _draftRow = null;
    _validationErrors.clear();

    _activeDynamicDatasource = null;
    _columns = [];
    _dataSource = LocalFitGridPlusDataSource(
      columns: const [],
      initialData: const [],
    );

    if (_fitController != null) {
      _fitController!.columns.columns = [];
      _fitController!.data.rows = [];
    }

    _activeGrouping.clear();
    _activeFilters.clear();
    _activeSortColumn = null;
    _searchQuery = '';
    _hiddenFields.clear();
    _activeExcelWorkbook = null;

    FitGridPlusDynamicStorage.setActiveDatasourceName(null);
    notifyListeners();
  }

  /// Parses an Excel (.xlsx) file into a [FitGridPlusExcelWorkbook].
  FitGridPlusExcelWorkbook parseExcel(
    Uint8List bytes, {
    String fileName = 'workbook.xlsx',
  }) {
    return FitGridPlusExcelParser.parseBytes(bytes, fileName: fileName);
  }

  /// Imports an Excel (.xlsx) workbook directly into the grid.
  Future<FitGridPlusExcelSheet?> importExcel({
    Uint8List? bytes,
    String? fileName,
    String? sheetName,
    BuildContext? context,
  }) async {
    Uint8List? fileBytes = bytes;
    String name = fileName ?? 'workbook.xlsx';

    if (fileBytes == null) {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (picked == null) return null;
      fileBytes = await picked.xFile.readAsBytes();
      name = picked.name;
    }

    final workbook = FitGridPlusExcelParser.parseBytes(
      fileBytes,
      fileName: name,
    );
    if (workbook.sheets.isEmpty) return null;
    _activeExcelWorkbook = workbook;

    FitGridPlusExcelSheet? selectedSheet;
    if (sheetName != null) {
      selectedSheet = workbook.getSheet(sheetName);
    }

    if (selectedSheet == null) {
      if (workbook.isMultiSheet && context != null && context.mounted) {
        selectedSheet = await FitGridPlusExcelSheetPickerDialog.show(
          context,
          workbook: workbook,
        );
        if (selectedSheet == null) return null;
      } else {
        selectedSheet = workbook.primarySheet;
      }
    }

    if (selectedSheet == null) return null;

    await loadExcelSheet(selectedSheet, fileName: name);

    return selectedSheet;
  }

  /// Loads a specific [FitGridPlusExcelSheet] into the grid.
  Future<void> loadExcelSheet(
    FitGridPlusExcelSheet sheet, {
    String? fileName,
  }) async {
    final name = fileName ?? _activeExcelWorkbook?.fileName ?? 'workbook.xlsx';
    final rawName = name
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase();
    final cleanSheet = sheet.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase();
    final dsName = rawName.isEmpty ? 'excel_dataset' : '${rawName}_$cleanSheet';
    final modelName = '${dsName}_mdl.yaml';
    final datasourceName = '$dsName.json';
    final now = DateTime.now();

    final dynamicModel = FitGridPlusDynamicModel(
      modelName: modelName,
      datasourceName: datasourceName,
      title: '${sheet.name} ($name)',
      sourceType: 'file',
      sourceOrigin: name,
      createdAt: now,
      columns: sheet.columns,
    );

    final descriptor = FitGridPlusDynamicDescriptor(
      name: dsName,
      modelName: modelName,
      datasourceName: datasourceName,
      title: dynamicModel.title,
      sourceType: 'file',
      sourceOrigin: name,
      rowCount: sheet.rows.length,
      createdAt: now,
      updatedAt: now,
      isReadonly: false,
    );

    await FitGridPlusDynamicStorage.saveDatasource(
      descriptor: descriptor,
      model: dynamicModel,
      rows: sheet.rows,
    );

    loadDynamicDatasource(
      descriptor,
      sheet.columns.map((c) => c.toFitGridPlusColumn()).toList(),
      sheet.rows,
    );
  }

  /// Opens the modal popup [FitGridPlusColumnEditorDialog] to edit a column's schema definition.
  Future<bool?> showColumnEditorDialog(
    BuildContext context, {
    required String field,
  }) {
    return FitGridPlusColumnEditorDialog.show(
      context,
      controller: this,
      field: field,
    );
  }

  /// Opens the modal popup [FitGridPlusColumnsEditorDialog] to edit and reorder all grid columns.
  Future<bool?> showColumnsEditorDialog(BuildContext context) {
    return FitGridPlusColumnsEditorDialog.show(context, controller: this);
  }

  void _updateGridRows(List<Map<String, dynamic>> newRows) {
    if (_fitController != null) {
      _fitController!.data.rows = List<Map<String, dynamic>>.from(newRows);
    }
    if (_dataSource is LocalFitGridPlusDataSource) {
      (_dataSource as LocalFitGridPlusDataSource).setData(newRows);
    }
    if (_activeDynamicDatasource != null &&
        !_activeDynamicDatasource!.isReadonly) {
      FitGridPlusDynamicStorage.updateDataRows(
        _activeDynamicDatasource!.name,
        newRows,
      );
    }
    notifyListeners();
  }

  /// Audits active grid data for anomalies and inconsistencies.
  FitGridPlusAuditReport auditData() {
    return FitGridPlusDataCleaner.audit(rows: rows, columns: _columns);
  }

  /// Applies targeted data cleaning [remediation] to active grid data.
  FitGridPlusCleanResult cleanData(FitGridPlusAuditRemediation remediation) {
    if (_activeDynamicDatasource?.isReadonly == true) {
      return FitGridPlusCleanResult(
        modifiedCount: 0,
        remainingRows: rows.length,
        message: 'Cannot clean read-only datasource',
        success: false,
      );
    }

    final initialRows = rows;
    final cleaned = FitGridPlusDataCleaner.applyRemediation(
      rows: initialRows,
      remediation: remediation,
      columns: _columns,
    );

    _updateGridRows(cleaned);

    final modified = initialRows.length != cleaned.length
        ? (initialRows.length - cleaned.length).abs()
        : initialRows.length;

    final result = FitGridPlusCleanResult(
      modifiedCount: modified,
      remainingRows: cleaned.length,
      message: 'Applied: ${remediation.description}',
    );

    logEditEvent(
      FitGridPlusEditEvent(
        action: 'cleanData',
        message: result.message,
        data: remediation.toJson(),
      ),
    );

    return result;
  }

  /// Automatically executes all remediation strategies across all fields.
  FitGridPlusCleanResult cleanAllData() {
    if (_activeDynamicDatasource?.isReadonly == true) {
      return FitGridPlusCleanResult(
        modifiedCount: 0,
        remainingRows: rows.length,
        message: 'Cannot clean read-only datasource',
        success: false,
      );
    }

    final initialRows = rows;
    final cleaned = FitGridPlusDataCleaner.cleanAll(
      initialRows,
      columns: _columns,
    );

    _updateGridRows(cleaned);

    final removed = initialRows.length - cleaned.length;
    final msg = removed > 0
        ? 'Cleaned all anomalies (removed $removed duplicate rows, normalized formats & numbers)'
        : 'Cleaned all anomalies across all columns';

    final result = FitGridPlusCleanResult(
      modifiedCount: cleaned.length,
      remainingRows: cleaned.length,
      message: msg,
    );

    logEditEvent(FitGridPlusEditEvent(action: 'cleanAllData', message: msg));

    return result;
  }

  /// Opens the modal popup [FitGridPlusDataAuditorDialog] to inspect data quality.
  Future<FitGridPlusCleanResult?> showDataAuditorDialog(BuildContext context) {
    return FitGridPlusDataAuditorDialog.show(context, controller: this);
  }

  /// Updates grid column definitions.
  void updateColumns(List<FitGridPlusColumn> newColumns, {bool notify = true}) {
    _columns = List<FitGridPlusColumn>.from(newColumns);
    if (_prePivotColumns != null) {
      _prePivotColumns = List<FitGridPlusColumn>.from(_columns);
    }
    if (_dataSource is LocalFitGridPlusDataSource) {
      _dataSource = LocalFitGridPlusDataSource(
        columns: _columns,
        initialData: (_dataSource as LocalFitGridPlusDataSource).data,
      );
    }
    _syncEffectiveColumns();
    if (notify) {
      notifyListeners();
    }
  }

  /// Updates all column definitions for this grid and persists to storage if dynamic.
  Future<bool> updateAllColumns(List<FitGridPlusColumn> newColumns) async {
    _columns = List<FitGridPlusColumn>.from(newColumns);
    if (_prePivotColumns != null) {
      _prePivotColumns = List<FitGridPlusColumn>.from(_columns);
    }

    if (_dataSource is LocalFitGridPlusDataSource) {
      _dataSource = LocalFitGridPlusDataSource(
        columns: _columns,
        initialData: (_dataSource as LocalFitGridPlusDataSource).data,
      );
    }

    _syncEffectiveColumns();
    if (_fitController != null) {
      for (final col in _columns) {
        if (col.width != null && col.width! > 0) {
          _fitController!.columns.setWidth(col.field, col.width!);
        }
      }
    }

    if (_activeDynamicDatasource != null &&
        !_activeDynamicDatasource!.isReadonly) {
      final existingModel = await FitGridPlusDynamicStorage.getModel(
        _activeDynamicDatasource!.name,
      );
      if (existingModel != null) {
        final updatedDynamicCols = _columns
            .map((c) => FitGridPlusDynamicColumnModel.fromFitGridPlusColumn(c))
            .toList();
        final updatedModel = existingModel.copyWith(
          columns: updatedDynamicCols,
        );
        await FitGridPlusDynamicStorage.updateModel(
          _activeDynamicDatasource!.name,
          updatedModel,
        );
      }
    }

    notifyListeners();
    return true;
  }

  /// Updates the schema definition of column [field].
  Future<bool> updateColumnDefinition({
    required String field,
    required String title,
    required FitGridPlusColumnType type,
    required bool editable,
    required bool required,
    double? width,
    double? maxWidth,
    FitGridPlusEditorType? editorType,
  }) async {
    final colIndex = _columns.indexWhere((c) => c.field == field);
    if (colIndex == -1) return false;
    final oldCol = _columns[colIndex];

    final updatedCol = FitGridPlusColumn(
      field: oldCol.field,
      title: title,
      type: type,
      width: width,
      minWidth: oldCol.minWidth,
      maxWidth: maxWidth,
      resizable: oldCol.resizable,
      isGroupable: oldCol.isGroupable,
      isSortable: oldCol.isSortable,
      isFilterable: oldCol.isFilterable,
      editable: editable,
      enableEditingMode: editable,
      editorIndex: oldCol.editorIndex,
      editorType: editorType,
      editorOptions: oldCol.editorOptions,
      validator: oldCol.validator,
      required: required,
      onChanged: oldCol.onChanged,
      editorBuilder: oldCol.editorBuilder,
      aggregateType: oldCol.aggregateType,
      numberFormat: oldCol.numberFormat,
      selectOptions: oldCol.selectOptions,
      cellBuilder: oldCol.cellBuilder,
    );

    final updatedColumns = List<FitGridPlusColumn>.from(_columns);
    updatedColumns[colIndex] = updatedCol;
    _columns = updatedColumns;

    if (_dataSource is LocalFitGridPlusDataSource) {
      _dataSource = LocalFitGridPlusDataSource(
        columns: updatedColumns,
        initialData: (_dataSource as LocalFitGridPlusDataSource).data,
      );
    }

    if (_fitController != null) {
      _fitController!.columns.columns = updatedColumns
          .map((c) => c.toFitGridColumn())
          .toList();
      if (width != null && width > 0) {
        _fitController!.columns.setWidth(field, width);
      }
    }

    if (_activeDynamicDatasource != null &&
        !_activeDynamicDatasource!.isReadonly) {
      final existingModel = await FitGridPlusDynamicStorage.getModel(
        _activeDynamicDatasource!.name,
      );
      if (existingModel != null) {
        final updatedDynamicCols = updatedColumns
            .map((c) => FitGridPlusDynamicColumnModel.fromFitGridPlusColumn(c))
            .toList();
        final updatedModel = existingModel.copyWith(
          columns: updatedDynamicCols,
        );
        await FitGridPlusDynamicStorage.updateModel(
          _activeDynamicDatasource!.name,
          updatedModel,
        );
      }
    }

    notifyListeners();
    return true;
  }

  /// The underlying cell range state, or null when not attached.
  FitGridCellRangeState? get cellRangeState => _fitController?.range;

  /// The active cell range selection rectangle.
  FitGridCellRange? get selectedCellRange => _fitController?.range.range;

  /// Whether a rectangular cell range is currently selected.
  bool get hasCellRangeSelection => _fitController?.range.isActive ?? false;

  /// Whether more than one cell is currently selected in the active range.
  bool get isMultiCellRangeSelected =>
      _fitController?.range.isMultiCell ?? false;

  /// Selects a rectangular range of cells.
  void selectCellRange({
    required int anchorRow,
    required String anchorColumn,
    required int extentRow,
    required String extentColumn,
    bool notify = true,
  }) {
    if (_fitController == null) return;
    _fitController!.range.range = FitGridCellRange(
      anchorRow: anchorRow,
      anchorColumnId: anchorColumn,
      extentRow: extentRow,
      extentColumnId: extentColumn,
    );
    if (notify) {
      notifyListeners();
    }
  }

  /// Selects a single cell as active range anchor.
  void selectCell(int row, String columnField, {bool notify = true}) {
    if (_fitController == null) return;
    _fitController!.range.select(row, columnField);
    if (notify) {
      notifyListeners();
    }
  }

  /// Clears active cell range selection.
  void clearCellRangeSelection({bool notify = true}) {
    if (_fitController == null) return;
    _fitController!.range.clear();
    if (notify) {
      notifyListeners();
    }
  }

  /// Computes summary metrics for selected cell range.
  FitGridPlusRangeSummary? calculateSelectedRangeSummary() {
    final range = _fitController?.range.range;
    if (range == null || _fitController == null) return null;

    final displayedCols = _fitController!.columns.columns
        .where((c) => c.visible)
        .map((c) => c.id)
        .toList();
    final colFields = range.columnIdsIn(displayedCols);
    if (colFields.isEmpty) return null;

    final rows = _fitController!.data.view;
    final selectedRows = <Map<String, dynamic>>[];
    for (var r = range.firstRow; r <= range.lastRow && r < rows.length; r++) {
      selectedRows.add(rows[r]);
    }

    return FitGridPlusRangeSummary.fromValues(
      rows: selectedRows,
      columnFields: colFields,
    );
  }

  /// Copies currently selected cell range to clipboard as TSV.
  Future<bool> copySelectedRangeToClipboard({
    bool includeHeaders = false,
  }) async {
    final range = _fitController?.range.range;
    if (range == null || _fitController == null) return false;

    final displayed = _fitController!.columns.columns
        .where((c) => c.visible)
        .toList();
    final colIds = range.columnIdsIn(displayed.map((c) => c.id).toList());
    if (colIds.isEmpty) return false;

    final buffer = StringBuffer();
    if (includeHeaders) {
      final headerTitles = colIds
          .map((id) {
            final col = displayed.firstWhere(
              (c) => c.id == id,
              orElse: () => displayed.first,
            );
            return col.label;
          })
          .join('\t');
      buffer.writeln(headerTitles);
    }

    final rows = _fitController!.data.view;
    for (var r = range.firstRow; r <= range.lastRow && r < rows.length; r++) {
      final row = rows[r];
      final line = colIds.map((id) => row[id]?.toString() ?? '').join('\t');
      buffer.writeln(line);
    }

    final text = buffer.toString().trimRight();
    if (text.isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  }

  // ---------------------------------------------------------------------------
  // Master-Detail & Expandable Child Row Operations
  // ---------------------------------------------------------------------------

  FitGridPlusMasterDetailOptions? _masterDetailOptions;
  Set<Object> _previousExpandedKeys = const <Object>{};

  /// Current master-detail options configured on this controller.
  FitGridPlusMasterDetailOptions? get masterDetailOptions =>
      _masterDetailOptions;

  /// Sets master-detail options and synchronizes initial expansion state.
  void setMasterDetailOptions(
    FitGridPlusMasterDetailOptions? options, {
    bool notify = true,
  }) {
    if (_masterDetailOptions == options) return;
    _masterDetailOptions = options;
    if (options != null &&
        options.initiallyExpandedKeys != null &&
        _fitController != null) {
      for (final key in options.initiallyExpandedKeys!) {
        _fitController!.details.setExpanded(key, true);
      }
      _previousExpandedKeys = Set<Object>.of(_fitController!.details.expanded);
    }
    if (notify) {
      notifyListeners();
    }
  }

  /// Whether master-detail child row expansion is active and enabled.
  bool get isMasterDetailEnabled => _masterDetailOptions?.enabled == true;

  /// Set of keys for currently expanded detail rows.
  Set<Object> get expandedDetailKeys =>
      _fitController?.details.expanded ?? const <Object>{};

  /// Whether any row detail panel is currently expanded.
  bool get hasExpandedDetails => expandedDetailKeys.isNotEmpty;

  /// Number of currently expanded detail panels.
  int get expandedDetailCount => expandedDetailKeys.length;

  /// Resolves the stable key for a given row map.
  Object resolveRowKey(Map<String, dynamic> row) {
    if (_masterDetailOptions?.rowKey != null) {
      return _masterDetailOptions!.rowKey!(row);
    }
    return (row['id'] ?? row['order_id'] ?? row['key'] ?? row) as Object;
  }

  /// Checks if a row with [rowKey] is currently expanded.
  bool isRowExpanded(Object rowKey) =>
      _fitController?.details.isExpanded(rowKey) ?? false;

  /// Checks if row at [rowIndex] in active view is currently expanded.
  bool isRowExpandedAt(int rowIndex) {
    if (_fitController == null) return false;
    final view = _fitController!.data.view;
    if (rowIndex < 0 || rowIndex >= view.length) return false;
    return isRowExpanded(resolveRowKey(view[rowIndex]));
  }

  /// Expands detail panel for the given [rowKey].
  void expandRow(Object rowKey) {
    if (_fitController == null) return;
    if (_masterDetailOptions?.autoCollapseOthers == true) {
      _fitController!.details.collapseAll();
    }
    _fitController!.details.setExpanded(rowKey, true);
  }

  /// Expands detail panel for row at [rowIndex].
  void expandRowAt(int rowIndex) {
    if (_fitController == null) return;
    final view = _fitController!.data.view;
    if (rowIndex < 0 || rowIndex >= view.length) return;
    expandRow(resolveRowKey(view[rowIndex]));
  }

  /// Collapses detail panel for the given [rowKey].
  void collapseRow(Object rowKey) {
    _fitController?.details.setExpanded(rowKey, false);
  }

  /// Collapses detail panel for row at [rowIndex].
  void collapseRowAt(int rowIndex) {
    if (_fitController == null) return;
    final view = _fitController!.data.view;
    if (rowIndex < 0 || rowIndex >= view.length) return;
    collapseRow(resolveRowKey(view[rowIndex]));
  }

  /// Toggles expansion for given [rowKey].
  void toggleRowDetail(Object rowKey) {
    if (_fitController == null) return;
    final willExpand = !isRowExpanded(rowKey);
    if (willExpand && _masterDetailOptions?.autoCollapseOthers == true) {
      _fitController!.details.collapseAll();
    }
    _fitController!.details.toggle(rowKey);
  }

  /// Toggles expansion for row at [rowIndex].
  void toggleRowDetailAt(int rowIndex) {
    if (_fitController == null) return;
    final view = _fitController!.data.view;
    if (rowIndex < 0 || rowIndex >= view.length) {
      return;
    }
    toggleRowDetail(resolveRowKey(view[rowIndex]));
  }

  /// Expands all rows in active view.
  void expandAllDetails() {
    if (_fitController == null ||
        _masterDetailOptions?.autoCollapseOthers == true) {
      return;
    }
    for (final row in _fitController!.data.view) {
      _fitController!.details.setExpanded(resolveRowKey(row), true);
    }
  }

  /// Collapses all currently expanded row details.
  void collapseAllDetails() {
    _fitController?.details.collapseAll();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _fitController?.data.removeListener(_onFitControllerChanged);
    _fitController?.columns.removeListener(_onFitControllerChanged);
    _fitController?.filter.removeListener(_onFitFilterChanged);
    _fitController?.range.removeListener(_onFitRangeChanged);
    _fitController?.details.removeListener(_onFitDetailsChanged);
    super.dispose();
  }

  void _onFitRangeChanged() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void _onFitDetailsChanged() {
    if (_disposed) return;
    final current = _fitController?.details.expanded ?? const <Object>{};

    if (_masterDetailOptions?.autoCollapseOthers == true &&
        current.length > 1) {
      final newlyAdded = current.difference(_previousExpandedKeys);
      if (newlyAdded.isNotEmpty) {
        final keepKey = newlyAdded.last;
        for (final k in List<Object>.from(current)) {
          if (k != keepKey) {
            _fitController?.details.setExpanded(k, false);
          }
        }
      }
    }

    final updated = _fitController?.details.expanded ?? const <Object>{};
    final added = updated.difference(_previousExpandedKeys);
    final removed = _previousExpandedKeys.difference(updated);
    _previousExpandedKeys = Set<Object>.of(updated);

    if (_masterDetailOptions?.onExpansionChanged != null) {
      for (final k in added) {
        _masterDetailOptions!.onExpansionChanged!(k, true);
      }
      for (final k in removed) {
        _masterDetailOptions!.onExpansionChanged!(k, false);
      }
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void _onFitFilterChanged() {
    if (_isApplyingFilters || _fitController == null) return;
    final currentFilters = _fitController!.filter.filters;
    _activeFilters.clear();
    for (final entry in currentFilters.entries) {
      _activeFilters[entry.key] = {
        'operator': entry.value.operator.name,
        'value':
            entry.value.value ??
            (entry.value.values.isNotEmpty
                ? entry.value.values.join(', ')
                : null),
        if (entry.value.value2 != null) 'value2': entry.value.value2,
        if (entry.value.values.isNotEmpty)
          'values': entry.value.values.toList(),
      };
    }
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    } else {
      notifyListeners();
    }
  }

  String? _resolveField(String name) {
    final clean = name.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    for (final col in _columns) {
      if (col.field.toLowerCase() == clean ||
          col.field.toLowerCase() == name.toLowerCase() ||
          col.title.toLowerCase().replaceAll(' ', '') == clean ||
          col.title.toLowerCase() == name.toLowerCase()) {
        return col.field;
      }
    }
    return name;
  }

  /// Sets multi-level hierarchical grouping by column fields.
  void setGrouping(List<String> fields, {bool notify = true}) {
    _activeGrouping = List.from(fields);
    if (_fitController != null) {
      if (fields.isEmpty) {
        _fitController!.grouping.groups = const [];
      } else {
        _fitController!.grouping.groups = fields.map((f) {
          final actual = _resolveField(f) ?? f;
          final col = _columns.where((c) => c.field == actual).firstOrNull;
          final title = col?.title ?? actual;
          return FitGridGroup<Map<String, dynamic>>(
            keyOf: (row) => row[actual]?.toString() ?? '',
            label: (key, rows) => '$title: $key (${rows.length})',
          );
        }).toList();
        _fitController!.grouping.expandAll();
      }
    }
    if (notify) {
      notifyListeners();
    }
  }

  /// Adds a column to active grouping.
  void addGroup(String field) {
    final actual = _resolveField(field) ?? field;
    if (!_activeGrouping.contains(actual)) {
      final updated = List<String>.from(_activeGrouping)..add(actual);
      setGrouping(updated);
    }
  }

  /// Removes a column from active grouping.
  void removeGroup(String field) {
    final actual = _resolveField(field) ?? field;
    final updated = List<String>.from(_activeGrouping);
    updated.removeWhere(
      (f) =>
          f == field ||
          f == actual ||
          f.toLowerCase() == field.toLowerCase() ||
          f.toLowerCase() == actual.toLowerCase(),
    );
    setGrouping(updated);
  }

  /// Clears all active grouping.
  void clearGrouping() {
    setGrouping([]);
  }

  FitGridFilterOperator _resolveFilterOperator(String operator) {
    final clean = operator
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    return switch (clean) {
      'notequals' ||
      'neq' ||
      'ne' ||
      '!=' ||
      '<>' ||
      'not' => FitGridFilterOperator.notEquals,
      'notcontains' ||
      'doesnotcontain' ||
      '!contains' ||
      'exclude' ||
      'excludes' => FitGridFilterOperator.notContains,
      'equals' || 'eq' || '=' || '==' => FitGridFilterOperator.equals,
      'startswith' => FitGridFilterOperator.startsWith,
      'endswith' => FitGridFilterOperator.endsWith,
      'greaterthan' || 'gt' || '>' => FitGridFilterOperator.greaterThan,
      'greaterthanorequalto' ||
      'greaterorequal' ||
      'gte' ||
      '>=' => FitGridFilterOperator.greaterOrEqual,
      'lessthan' || 'lt' || '<' => FitGridFilterOperator.lessThan,
      'lessthanorequalto' ||
      'lessorequal' ||
      'lte' ||
      '<=' => FitGridFilterOperator.lessOrEqual,
      'between' => FitGridFilterOperator.between,
      'isempty' => FitGridFilterOperator.isEmpty,
      'isnotempty' => FitGridFilterOperator.isNotEmpty,
      'inlist' ||
      'oneof' ||
      'in' ||
      'or' ||
      'anyof' ||
      'either' => FitGridFilterOperator.inList,
      _ => FitGridFilterOperator.contains,
    };
  }

  void _applyActiveFilters() {
    if (_fitController == null) return;
    _isApplyingFilters = true;
    try {
      final activeFields = _activeFilters.keys.toSet();
      for (final existingField
          in _fitController!.filter.filters.keys.toList()) {
        if (!activeFields.contains(existingField)) {
          _fitController!.filter.setFilter(existingField, null);
        }
      }

      for (final entry in _activeFilters.entries) {
        final field = entry.key;
        final opName = (entry.value['operator'] as String?) ?? 'contains';
        final val = entry.value['value'];
        var op = _resolveFilterOperator(opName);

        if (val is Iterable) {
          op = FitGridFilterOperator.inList;
        } else if (val is String &&
            (op == FitGridFilterOperator.contains ||
                op == FitGridFilterOperator.equals)) {
          final trimmed = val.trim();
          if (trimmed.toLowerCase().startsWith('in:') ||
              trimmed.toLowerCase().contains(RegExp(r'\s+or\s+'))) {
            op = FitGridFilterOperator.inList;
          }
        }

        final col = _columns.where((c) => c.field == field).firstOrNull;
        Object? operand = val;
        Set<String> setValues = const <String>{};

        if (op == FitGridFilterOperator.inList) {
          if (val is Iterable) {
            setValues = val
                .map((e) => e.toString().trim())
                .where((s) => s.isNotEmpty)
                .toSet();
          } else if (val is String) {
            var raw = val.trim();
            if (raw.toLowerCase().startsWith('in:')) {
              raw = raw.substring(3).trim();
            } else if (raw.toLowerCase().startsWith('in(') &&
                raw.endsWith(')')) {
              raw = raw.substring(3, raw.length - 1).trim();
            }
            setValues = raw
                .split(RegExp(r'\s*,\s*|\s+or\s+|\|', caseSensitive: false))
                .map((e) => e.trim())
                .where((s) => s.isNotEmpty)
                .toSet();
          } else if (val != null) {
            setValues = {val.toString().trim()};
          }
          operand = setValues.join(', ');
        } else if (col != null) {
          if (col.type == FitGridPlusColumnType.number ||
              col.type == FitGridPlusColumnType.currency) {
            if (val is! num && val != null) {
              operand = num.tryParse(
                val.toString().replaceAll(RegExp(r'[^0-9.-]'), ''),
              );
            }
          } else if (col.type == FitGridPlusColumnType.date) {
            if (val is! DateTime && val != null) {
              operand = DateTime.tryParse(val.toString());
            }
          }
        }

        _fitController!.filter.setFilter(
          field,
          FitGridColumnFilter(operator: op, value: operand, values: setValues),
        );
      }
    } finally {
      _isApplyingFilters = false;
    }
  }

  /// Applies a column filter.
  void setFilter(
    String field, {
    required String operator,
    required dynamic value,
  }) {
    final actualField = _resolveField(field) ?? field;
    _activeFilters[actualField] = {'operator': operator, 'value': value};
    _applyActiveFilters();
    notifyListeners();
  }

  /// Applies multiple column filters at once joined by AND.
  void setFilters(List<Map<String, dynamic>> filters, {bool replace = false}) {
    if (replace) {
      _activeFilters.clear();
    }
    for (final f in filters) {
      final field = (f['column'] ?? f['field']) as String?;
      if (field == null) continue;
      final actualField = _resolveField(field) ?? field;
      final op = (f['operator'] as String?) ?? 'contains';
      final val = f['value'];
      _activeFilters[actualField] = {'operator': op, 'value': val};
    }
    _applyActiveFilters();
    notifyListeners();
  }

  /// Removes filter from a specific column.
  void removeFilter(String field) {
    final actualField = _resolveField(field) ?? field;
    _activeFilters.remove(field);
    _activeFilters.remove(actualField);
    _fitController?.filter.setFilter(actualField, null);
    if (actualField != field) {
      _fitController?.filter.setFilter(field, null);
    }
    notifyListeners();
  }

  /// Clears all column filters.
  void clearAllFilters() {
    _activeFilters.clear();
    _fitController?.filter.clearColumnFilters();
    notifyListeners();
  }

  /// Performs an in-built mathematical calculation over grid rows.
  Map<String, dynamic> calculate({
    required String field,
    required String operation,
    bool filteredOnly = true,
    String? groupBy,
  }) {
    if (_fitController == null && _dataSource == null) {
      return {'error': 'Grid is not initialized'};
    }

    final actualField = _resolveField(field) ?? field;
    final String columnTitle =
        _columns.where((c) => c.field == actualField).firstOrNull?.title ??
        actualField;

    final targetColumn = _columns
        .where((c) => c.field == actualField)
        .firstOrNull;

    List<Map<String, dynamic>> rows = [];
    if (_fitController != null) {
      rows = filteredOnly
          ? _fitController!.data.view
          : _fitController!.data.rows;
    } else if (_dataSource is LocalFitGridPlusDataSource) {
      rows = (_dataSource as LocalFitGridPlusDataSource).data;
    }

    if (groupBy != null && groupBy.isNotEmpty) {
      final actualGroupField = _resolveField(groupBy) ?? groupBy;
      final String groupTitle =
          _columns
              .where((c) => c.field == actualGroupField)
              .firstOrNull
              ?.title ??
          actualGroupField;

      final groups = <dynamic, List<num>>{};
      for (final row in rows) {
        final gVal = row[actualGroupField]?.toString() ?? 'Unknown';
        final val = row[actualField];
        if (val is num) {
          groups.putIfAbsent(gVal, () => []).add(val);
        } else if (val != null) {
          final parsed = num.tryParse(
            val.toString().replaceAll(RegExp(r'[^0-9.-]'), ''),
          );
          if (parsed != null) {
            groups.putIfAbsent(gVal, () => []).add(parsed);
          }
        }
      }

      final results = <String, dynamic>{};
      for (final entry in groups.entries) {
        results[entry.key.toString()] = _computeStats(
          entry.value,
          operation,
          targetColumn,
        );
      }

      return {
        'field': actualField,
        'columnTitle': columnTitle,
        'operation': operation,
        'groupedBy': groupTitle,
        'filteredOnly': filteredOnly,
        'results': results,
        'groups': results,
      };
    }

    final numbers = <num>[];
    for (final row in rows) {
      final val = row[actualField];
      if (val is num) {
        numbers.add(val);
      } else if (val != null) {
        final parsed = num.tryParse(
          val.toString().replaceAll(RegExp(r'[^0-9.-]'), ''),
        );
        if (parsed != null) numbers.add(parsed);
      }
    }

    final stats = _computeStats(numbers, operation, targetColumn);
    return {
      'field': actualField,
      'columnTitle': columnTitle,
      'operation': operation,
      'filteredOnly': filteredOnly,
      'rowCount': numbers.length,
      ...stats,
    };
  }

  Map<String, dynamic> _computeStats(
    List<num> numbers,
    String operation,
    FitGridPlusColumn? column,
  ) {
    if (numbers.isEmpty) {
      return {'result': 0.0, 'formatted': '0', 'count': 0};
    }

    final op = operation.toLowerCase();
    num result;
    if (op.contains('avg') || op.contains('mean') || op.contains('average')) {
      final sum = numbers.reduce((a, b) => a + b);
      result = sum / numbers.length;
    } else if (op.contains('sum') || op.contains('total')) {
      result = numbers.reduce((a, b) => a + b);
    } else if (op.contains('min')) {
      result = numbers.reduce(math.min);
    } else if (op.contains('max')) {
      result = numbers.reduce(math.max);
    } else if (op.contains('count')) {
      result = numbers.length;
    } else if (op.contains('median')) {
      final sorted = List<num>.from(numbers)..sort();
      final middle = sorted.length ~/ 2;
      result = sorted.length.isOdd
          ? sorted[middle]
          : (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      final sum = numbers.reduce((a, b) => a + b);
      result = sum / numbers.length;
    }

    String formatted = result.toStringAsFixed(2);
    if (column != null && column.type == FitGridPlusColumnType.currency) {
      formatted = '\$${result.toStringAsFixed(2)}';
    }

    return {
      'result': double.parse(result.toStringAsFixed(2)),
      'formatted': formatted,
      'count': numbers.length,
    };
  }

  // ===========================================================================
  // Pivot Table Support
  // ===========================================================================

  FitGridPlusPivotConfig? _pivotConfig;
  List<Map<String, dynamic>>? _prePivotRows;
  List<FitGridPlusColumn>? _prePivotColumns;
  List<String>? _prePivotGrouping;
  FitGridPlusPivotChartData? _pivotChartData;
  List<FitGridColumnGroup> _pivotColumnGroups = const [];

  /// Whether grid is currently displaying in aggregated Pivot Mode.
  bool get isPivotActive => _pivotConfig != null;

  /// Active pivot configuration.
  FitGridPlusPivotConfig? get pivotConfig => _pivotConfig;

  /// Active banded column groups generated for pivot mode.
  List<FitGridColumnGroup> get pivotColumnGroups =>
      List.unmodifiable(_pivotColumnGroups);

  /// Computed chart series data derived from active pivot.
  FitGridPlusPivotChartData? get pivotChartData => _pivotChartData;

  /// Original column definitions before pivot mode was activated.
  List<FitGridPlusColumn> get originalColumns => _prePivotColumns ?? _columns;

  /// Alias for [setPivot].
  void applyPivot(FitGridPlusPivotConfig config) => setPivot(config);

  /// Transforms the grid on-the-fly into an aggregated Pivot Table.
  void setPivot(FitGridPlusPivotConfig config) {
    if (config.rowFieldIds.isEmpty && config.columnFieldIds.isEmpty) {
      throw ArgumentError(
        'Pivot requires at least one row field or column field.',
      );
    }
    if (config.values.isEmpty) {
      throw ArgumentError('Pivot requires at least one value field.');
    }

    final sourceRows =
        _prePivotRows ??
        List<Map<String, dynamic>>.from(
          _fitController?.data.rows ??
              (_dataSource is LocalFitGridPlusDataSource
                  ? (_dataSource as LocalFitGridPlusDataSource).data
                  : const <Map<String, dynamic>>[]),
        );
    if (sourceRows.isEmpty) return;

    _prePivotRows ??= sourceRows;
    _prePivotColumns ??= List<FitGridPlusColumn>.from(_columns);
    _prePivotGrouping ??= List<String>.from(_activeGrouping);

    final pivotResult = FitGridPlusPivotEngine.execute(
      rows: sourceRows,
      columns: _prePivotColumns!,
      config: config,
    );

    _pivotColumnGroups = pivotResult.columnGroups;
    _pivotChartData = pivotResult.chartData;
    _pivotConfig = config;
    _columns = pivotResult.columns;

    if (_fitController != null) {
      _fitController!.columns.columns = pivotResult.columns
          .map((c) => c.toFitGridColumn())
          .toList();
      _fitController!.data.rows = pivotResult.rows;

      if (config.groupByRows && config.rowFieldIds.length > 1) {
        final groupFields = config.rowFieldIds
            .take(config.rowFieldIds.length - 1)
            .toList();
        setGrouping(groupFields);
      } else {
        setGrouping([]);
      }
    }

    notifyListeners();
  }

  /// Restores the grid to the original standard editable table.
  void clearPivot() {
    if (!isPivotActive) return;

    final origRows = _prePivotRows;
    final origCols = _prePivotColumns;
    final origGrouping = _prePivotGrouping;

    _pivotConfig = null;
    _pivotColumnGroups = const [];
    _pivotChartData = null;
    _prePivotRows = null;
    _prePivotColumns = null;
    _prePivotGrouping = null;

    if (origCols != null) {
      _columns = origCols;
    }

    if (_fitController != null) {
      if (origCols != null) {
        _fitController!.columns.columns = origCols
            .map((c) => c.toFitGridColumn())
            .toList();
      }
      if (origRows != null) {
        _fitController!.data.rows = origRows;
      }
      if (origGrouping != null && origGrouping.isNotEmpty) {
        setGrouping(origGrouping);
      } else {
        clearGrouping();
      }
    }

    notifyListeners();
  }

  /// Toggles visibility of side-by-side pivot chart.
  void togglePivotChart([bool? show]) {
    if (_pivotConfig == null) return;
    _pivotConfig = _pivotConfig!.copyWith(
      showChart: show ?? !_pivotConfig!.showChart,
    );
    notifyListeners();
  }

  /// Updates active pivot chart visualization type.
  void setPivotChartType(FitGridPlusPivotChartType type) {
    if (_pivotConfig == null) return;
    _pivotConfig = _pivotConfig!.copyWith(chartType: type);
    notifyListeners();
  }

  /// Applies global text search across all columns.
  void search(String query, {bool notify = true}) {
    _searchQuery = query;
    _fitController?.filter.query = query.trim();
    if (notify) {
      notifyListeners();
    }
  }

  /// Alias for [search].
  void setSearchQuery(String query) => search(query);

  /// Clears global search.
  void clearSearch() {
    search('');
  }

  /// Applies column sorting.
  void sort(
    String field, {
    bool descending = false,
    bool append = false,
    bool notify = true,
  }) {
    final actual = _resolveField(field) ?? field;
    final dir = descending
        ? FitGridSortDirection.descending
        : FitGridSortDirection.ascending;

    if (_fitController != null) {
      if (!append) {
        _fitController!.setSort([FitGridSortKey(actual, dir)]);
      } else {
        final existing = _fitController!.data.sortKeys
            .where((k) => k.columnId != actual)
            .toList();
        existing.add(FitGridSortKey(actual, dir));
        _fitController!.setSort(existing);
      }
    }

    _activeSortColumn = field;
    _isSortDescending = descending;
    if (notify) {
      notifyListeners();
    }
  }

  /// Sets column sorting.
  void setSorting(
    String field, {
    bool descending = false,
    bool append = false,
  }) => sort(field, descending: descending, append: append);

  /// Applies multi-column sorting.
  void multiSort(List<Map<String, dynamic>> sortConfigs) {
    if (sortConfigs.isEmpty) return;

    final keys = <FitGridSortKey>[];
    for (final config in sortConfigs) {
      final field = (config['field'] ?? config['column']) as String?;
      if (field == null) continue;
      final actual = _resolveField(field) ?? field;
      final descending = (config['descending'] as bool?) ?? false;
      keys.add(
        FitGridSortKey(
          actual,
          descending
              ? FitGridSortDirection.descending
              : FitGridSortDirection.ascending,
        ),
      );
    }

    _fitController?.setSort(keys);

    if (sortConfigs.isNotEmpty) {
      _activeSortColumn =
          (sortConfigs.first['field'] ?? sortConfigs.first['column'])
              as String?;
      _isSortDescending = (sortConfigs.first['descending'] as bool?) ?? false;
    }
    notifyListeners();
  }

  /// Returns current sorted keys.
  List<FitGridSortKey> get sortedColumns => _fitController?.data.sortKeys ?? [];

  /// Clears column sorting.
  void clearSorting() {
    _fitController?.clearSort();
    _activeSortColumn = null;
    _isSortDescending = false;
    notifyListeners();
  }

  /// Sets visibility of a specific column.
  void setColumnVisibility(String field, bool visible) {
    final actual = _resolveField(field) ?? field;
    if (visible) {
      _hiddenFields.remove(actual);
    } else {
      _hiddenFields.add(actual);
    }
    _fitController?.columns.setVisible(actual, visible);
    notifyListeners();
  }

  /// Shows ONLY the specified columns and hides all other columns.
  void showOnlyColumns(List<String> fields) {
    final targetFields = fields.map((f) => _resolveField(f) ?? f).toSet();
    _hiddenFields.clear();
    _hiddenFields.addAll(
      _columns.map((c) => c.field).where((f) => !targetFields.contains(f)),
    );

    if (_fitController != null) {
      for (final col in _columns) {
        _fitController!.columns.setVisible(
          col.field,
          targetFields.contains(col.field),
        );
      }
    }
    notifyListeners();
  }

  /// Sets visibility for multiple columns at once.
  void setColumnsVisibility(Map<String, bool> visibilityMap) {
    for (final entry in visibilityMap.entries) {
      final actual = _resolveField(entry.key) ?? entry.key;
      if (entry.value) {
        _hiddenFields.remove(actual);
      } else {
        _hiddenFields.add(actual);
      }
      _fitController?.columns.setVisible(actual, entry.value);
    }
    notifyListeners();
  }

  /// Restores visibility of all columns.
  void showAllColumns() {
    _hiddenFields.clear();
    _fitController?.columns.showAll();
    notifyListeners();
  }

  /// Returns list of currently visible column fields.
  List<String> get visibleColumns {
    if (_fitController != null) {
      return _fitController!.columns.visible.map((c) => c.id).toList();
    }
    return _columns
        .map((c) => c.field)
        .where((f) => !_hiddenFields.contains(f))
        .toList();
  }

  /// Returns list of currently hidden column fields.
  List<String> get hiddenColumns {
    if (_fitController != null) {
      return _fitController!.columns.columns
          .where((c) => !c.visible)
          .map((c) => c.id)
          .toList();
    }
    return _hiddenFields.toList();
  }

  /// Sets explicit width in pixels for a column.
  void setColumnWidth(String field, double width) {
    final actual = _resolveField(field) ?? field;
    _fitController?.columns.setWidth(actual, width);
    notifyListeners();
  }

  /// Restores column to auto-fitting width policy.
  void autoSizeColumn(String field) {
    final actual = _resolveField(field) ?? field;
    _fitController?.columns.autoSize(actual);
    notifyListeners();
  }

  /// Restores all columns to declared width policies.
  void autoSizeAllColumns() {
    _fitController?.columns.autoSizeAll();
    notifyListeners();
  }

  /// Map of column fields to explicit width overrides.
  Map<String, double> get columnWidths =>
      _fitController?.columns.widthOverrides ?? const {};

  /// Whether a column currently has a width override.
  bool isColumnResized(String field) {
    final actual = _resolveField(field) ?? field;
    return _fitController?.columns.isResized(actual) ?? false;
  }

  /// Toggles visibility of inline filter row.
  void toggleFilterRow() {
    _showColumnFilterRow = !_showColumnFilterRow;
    notifyListeners();
  }

  /// Alias for [toggleFilterRow].
  void toggleColumnFilterRow() => toggleFilterRow();

  /// Toggles visibility of top group panel.
  void toggleGroupPanel() {
    _showGroupPanel = !_showGroupPanel;
    notifyListeners();
  }

  /// Resets grid to default state.
  void reset() {
    clearGrouping();
    clearAllFilters();
    clearSearch();
    clearSorting();
    showAllColumns();
  }

  /// Exports native [FitGridSavedState] snapshot directly.
  FitGridSavedState? saveLayoutState() => _fitController?.saveState();

  /// Restores native [FitGridSavedState] snapshot directly.
  void restoreLayoutState(FitGridSavedState state) {
    if (_fitController != null) {
      _fitController!.restoreState(state);
      _activeSortColumn = state.sort.isNotEmpty
          ? state.sort.first.columnId
          : null;
      _isSortDescending =
          state.sort.isNotEmpty &&
          state.sort.first.direction == FitGridSortDirection.descending;
      _searchQuery = state.query;
      _hiddenFields.clear();
      _hiddenFields.addAll(state.hiddenColumns);
      notifyListeners();
    }
  }

  /// Exports all current interactive grid settings to a Map.
  Map<String, dynamic> exportSettings() {
    final fitState =
        _fitController?.saveState().toJson() ?? <String, dynamic>{};

    return {
      ...fitState,
      'viewMode': _viewMode.name,
      'groupColumns': List<String>.from(activeGrouping),
      'showColumnFilterRow': _showColumnFilterRow,
      'showGroupPanel': _showGroupPanel,
      'visibleColumns': visibleColumns,
      'hiddenColumns': hiddenColumns,
      'sorts':
          _fitController != null && _fitController!.data.sortKeys.isNotEmpty
          ? _fitController!.data.sortKeys
                .map(
                  (k) => {
                    'field': k.columnId,
                    'descending':
                        k.direction == FitGridSortDirection.descending,
                  },
                )
                .toList()
          : (_activeSortColumn != null
                ? [
                    {
                      'field': _activeSortColumn,
                      'descending': _isSortDescending,
                    },
                  ]
                : <Map<String, dynamic>>[]),
      'filters': Map<String, dynamic>.from(activeFilters),
      'conditionalFormats': _conditionalFormats.map((f) => f.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Exports all current settings serialized as JSON string.
  String exportSettingsJson({bool pretty = true}) {
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(exportSettings());
  }

  /// Restores grid state from a saved settings Map.
  void restoreSettings(Map<String, dynamic> settings) {
    if (_fitController != null) {
      try {
        final fitState = FitGridSavedState.fromJson(settings);
        _fitController!.restoreState(fitState);

        if (fitState.sort.isNotEmpty) {
          _activeSortColumn = fitState.sort.first.columnId;
          _isSortDescending =
              fitState.sort.first.direction == FitGridSortDirection.descending;
        } else if (!settings.containsKey('sorts')) {
          _activeSortColumn = null;
          _isSortDescending = false;
        }

        if (fitState.query.isNotEmpty) {
          _searchQuery = fitState.query;
        }

        if (fitState.hiddenColumns.isNotEmpty) {
          _hiddenFields.clear();
          _hiddenFields.addAll(fitState.hiddenColumns);
        }
      } catch (e) {
        debugPrint('Error restoring FitGridSavedState: $e');
      }
    }

    if (!settings.containsKey('columnOrder')) {
      if (settings.containsKey('visibleColumns')) {
        final list = (settings['visibleColumns'] as List?)
            ?.map((e) => e.toString())
            .toList();
        if (list != null && list.isNotEmpty) {
          showOnlyColumns(list);
        }
      } else if (settings.containsKey('hiddenColumns')) {
        final hidden =
            (settings['hiddenColumns'] as List?)
                ?.map((e) => e.toString())
                .toSet() ??
            {};
        final map = <String, bool>{};
        for (final col in _columns) {
          map[col.field] = !hidden.contains(col.field);
        }
        setColumnsVisibility(map);
      }
    }

    if (settings.containsKey('filters')) {
      final filters = settings['filters'] as Map<String, dynamic>? ?? {};
      clearAllFilters();
      for (final entry in filters.entries) {
        final valMap = entry.value as Map<String, dynamic>?;
        if (valMap != null) {
          final op =
              (valMap['operator'] ?? valMap['op'])?.toString() ?? 'contains';
          final val = valMap['value'];
          setFilter(entry.key, operator: op, value: val);
        }
      }
    }

    if (settings.containsKey('sorts')) {
      final sorts =
          (settings['sorts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (sorts.isNotEmpty) {
        multiSort(sorts);
      } else {
        clearSorting();
      }
    } else if (settings.containsKey('sort')) {
      final sorts =
          (settings['sort'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (sorts.isNotEmpty) {
        multiSort(
          sorts
              .map(
                (s) => {
                  'field': s['column'],
                  'descending': s['dir'] == 'descending',
                },
              )
              .toList(),
        );
      }
    }

    if (settings.containsKey('groupColumns')) {
      final groups =
          (settings['groupColumns'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (groups.isNotEmpty || _activeGrouping.isNotEmpty) {
        setGrouping(groups);
      }
    }

    if (settings.containsKey('viewMode')) {
      final modeStr = settings['viewMode']?.toString();
      _viewMode = FitGridPlusViewMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => FitGridPlusViewMode.grid,
      );
    }
    if (settings.containsKey('showColumnFilterRow')) {
      _showColumnFilterRow = settings['showColumnFilterRow'] == true;
    }
    if (settings.containsKey('showGroupPanel')) {
      _showGroupPanel = settings['showGroupPanel'] == true;
    }

    if (settings['conditionalFormats'] is List) {
      _conditionalFormats.clear();
      for (final item in settings['conditionalFormats'] as List) {
        if (item is Map<String, dynamic>) {
          _conditionalFormats.add(FitGridPlusConditionalFormat.fromJson(item));
        }
      }
      _syncEffectiveColumns();
    }

    notifyListeners();
  }

  /// Restores grid state from a JSON string.
  void restoreSettingsJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        restoreSettings(decoded);
      }
    } catch (e) {
      debugPrint('Error restoring grid settings from JSON: $e');
    }
  }

  /// Exports current grid data to Excel (.xlsx) using FitGrid's native XLSX encoder.
  Future<String?> export({
    String? fileName,
    bool includeHeaders = true,
    bool selectedOnly = false,
  }) => exportTableWithSaveDialog(
    fileName: fileName,
    includeHeaders: includeHeaders,
    selectedOnly: selectedOnly,
  );

  /// Exports current grid data to Excel (.xlsx) with platform Save As dialog.
  Future<String?> exportTableWithSaveDialog({
    String? fileName,
    bool includeHeaders = true,
    bool selectedOnly = false,
  }) async {
    final fc = _fitController;
    if (fc == null) throw Exception('Grid is not attached yet');

    final exportData = fc.export(
      includeHeaders: includeHeaders,
      selectedOnly: selectedOnly,
    );

    final bytes = fitGridToXlsx(exportData);
    final rawName = (fileName != null && fileName.trim().isNotEmpty)
        ? fileName.trim()
        : 'grid_export_${DateTime.now().millisecondsSinceEpoch}';
    final cleanName = rawName.replaceAll(
      RegExp(r'\.xlsx$', caseSensitive: false),
      '',
    );

    try {
      final savedPath = await FileSaver.instance.saveAs(
        name: cleanName,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
        dialogTitle: 'Export Grid Data to Excel',
      );
      return savedPath;
    } on UnsupportedError catch (e) {
      debugPrint(
        'saveAs unsupported on platform ($e), falling back to saveFile',
      );
      return await FileSaver.instance.saveFile(
        name: cleanName,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      debugPrint('saveAs error ($e), falling back to saveFile');
      return await FileSaver.instance.saveFile(
        name: cleanName,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    }
  }

  /// Exports current grid data to CSV, TSV, XLSX, or JSON.
  Future<String> exportGrid({
    String format = 'xlsx',
    List<String>? columns,
    bool includeHeaders = true,
    bool ignoreFixedRows = false,
    String separator = ',',
    bool useSaveAs = true,
    String? fileName,
    bool selectedOnly = false,
  }) async {
    final fc = _fitController;
    if (fc == null) throw Exception('Grid is not attached yet');

    final rawName = (fileName != null && fileName.trim().isNotEmpty)
        ? fileName.trim()
        : 'grid_export_${DateTime.now().millisecondsSinceEpoch}';
    final fmt = format.toLowerCase().trim();

    final exportData = fc.export(
      includeHeaders: includeHeaders,
      selectedOnly: selectedOnly,
    );

    Uint8List bytes;
    String extension;
    MimeType mimeType;

    if (fmt == 'xlsx') {
      bytes = fitGridToXlsx(exportData);
      extension = 'xlsx';
      mimeType = MimeType.microsoftExcel;
    } else if (fmt == 'csv') {
      final content = fitGridToCsv(exportData);
      bytes = Uint8List.fromList(utf8.encode(content));
      extension = 'csv';
      mimeType = MimeType.csv;
    } else if (fmt == 'tsv') {
      final content = fitGridToTsv(exportData);
      bytes = Uint8List.fromList(utf8.encode(content));
      extension = 'tsv';
      mimeType = MimeType.text;
    } else if (fmt == 'json') {
      final rows = fc.data.view;
      final jsonStr = const JsonEncoder.withIndent('  ').convert(rows);
      bytes = Uint8List.fromList(utf8.encode(jsonStr));
      extension = 'json';
      mimeType = MimeType.json;
    } else {
      throw Exception('Unsupported export format: $format');
    }

    final cleanName = rawName.replaceAll(
      RegExp('\\.$extension\$', caseSensitive: false),
      '',
    );

    if (useSaveAs) {
      try {
        final path = await FileSaver.instance.saveAs(
          name: cleanName,
          bytes: bytes,
          fileExtension: extension,
          mimeType: mimeType,
          dialogTitle: 'Export Grid Data',
        );
        if (path != null && path.isNotEmpty) {
          return path;
        }
      } catch (e) {
        debugPrint('FileSaver.saveAs failed ($e), falling back to saveFile');
      }
    }

    return await FileSaver.instance.saveFile(
      name: cleanName,
      bytes: bytes,
      fileExtension: extension,
      mimeType: mimeType,
    );
  }
}
