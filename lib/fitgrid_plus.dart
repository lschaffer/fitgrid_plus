/// Pure Flutter enterprise virtualized canvas DataGrid package with zero AI/LLM/MCP overhead.
///
/// Combines the high-performance [FitGrid] canvas engine with enterprise capabilities:
/// - DevExtreme-style editing (inline cell, inline row, and modal form popup)
/// - Dynamic Pivot Grids with banded column headers and canvas split charts
/// - Multi-level hierarchical grouping with drag/drop chip panel
/// - Pure Dart Excel (.xlsx), CSV, TSV, and JSON import & export
/// - Mobile responsive card feed with swipe actions
/// - Rectangular cell range selection and instant summary statistics
/// - Deterministic data quality auditing and 1-click anomaly cleaning
/// - SharedPreferences layout persistence
library;

// -----------------------------------------------------------------------------
// Core High-Performance Canvas Engine
// -----------------------------------------------------------------------------
export 'src/core/fitgrid_table.dart';

// -----------------------------------------------------------------------------
// Enterprise Models
// -----------------------------------------------------------------------------
export 'src/enterprise/models/fitgrid_plus_column.dart';
export 'src/enterprise/models/fitgrid_plus_conditional_format.dart';
export 'src/enterprise/models/fitgrid_plus_context_action.dart';
export 'src/enterprise/models/fitgrid_plus_data_auditor.dart';
export 'src/enterprise/models/fitgrid_plus_data_source.dart';
export 'src/enterprise/models/fitgrid_plus_dynamic_datasource.dart';
export 'src/enterprise/models/fitgrid_plus_editing_options.dart';
export 'src/enterprise/models/fitgrid_plus_master_detail.dart';
export 'src/enterprise/models/fitgrid_plus_pivot.dart';
export 'src/enterprise/models/fitgrid_plus_range_summary.dart';
export 'src/enterprise/models/fitgrid_plus_view_mode.dart';

// -----------------------------------------------------------------------------
// Enterprise Controller
// -----------------------------------------------------------------------------
export 'src/enterprise/controllers/fitgrid_plus_controller.dart';

// -----------------------------------------------------------------------------
// Enterprise Data Parsers, Cleaners
// -----------------------------------------------------------------------------
export 'src/enterprise/data/clipboard_content_service.dart';
export 'src/enterprise/data/delimited_table_parser.dart';
export 'src/enterprise/data/excel_table_parser.dart';
export 'src/enterprise/data/fitgrid_plus_data_cleaner.dart';
export 'src/enterprise/data/markdown_table_extractor.dart';

// -----------------------------------------------------------------------------
// Enterprise Theme & Storage Configuration
// -----------------------------------------------------------------------------
export 'src/enterprise/config/fitgrid_plus_dynamic_storage.dart';
export 'src/enterprise/config/fitgrid_plus_settings_storage.dart';
export 'src/enterprise/theme/fitgrid_plus_theme.dart';

// -----------------------------------------------------------------------------
// Enterprise Widgets & Dialogs
// -----------------------------------------------------------------------------
export 'src/enterprise/widgets/fitgrid_plus.dart';
export 'src/enterprise/widgets/fitgrid_plus_card_view.dart';
export 'src/enterprise/widgets/fitgrid_plus_column_editor_dialog.dart';
export 'src/enterprise/widgets/fitgrid_plus_columns_editor_dialog.dart';
export 'src/enterprise/widgets/fitgrid_plus_context_menu.dart';
export 'src/enterprise/widgets/fitgrid_plus_data_auditor_dialog.dart';
export 'src/enterprise/widgets/fitgrid_plus_datasource_dialogs.dart';
export 'src/enterprise/widgets/fitgrid_plus_excel_dialogs.dart';
export 'src/enterprise/widgets/fitgrid_plus_form_dialog.dart';
export 'src/enterprise/widgets/fitgrid_plus_group_panel.dart';
export 'src/enterprise/widgets/fitgrid_plus_pivot_chart.dart';
export 'src/enterprise/widgets/fitgrid_plus_pivot_chooser_dialog.dart';
export 'src/enterprise/widgets/fitgrid_plus_toolbar.dart';
