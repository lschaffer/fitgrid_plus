# Changelog

## 0.1.1

- **Live Demo**: Launched interactive web showcase at [https://tealkit.dev/fitgrid_plus/](https://tealkit.dev/fitgrid_plus/).
- **Example Source Navigation**: Added direct 1-click GitHub source code links to all showcase examples and top app bar.
- **Dynamic Table Ingestion**: Added dynamic column editor and sample dataset loaders (CSV, TSV, Markdown tables, YAML).
- **Pagination Bug Fix**: Fixed pagination toggle so paging can be dynamically disabled/enabled without `pageSize` permanently forcing pagination active.
- **Editing Enhancements**:
  - Fixed horizontal scrollbar visibility and grid tab navigation in row edit mode.
  - Fixed dropdown picker stability and overlay cleanup on Flutter Web.
- **Responsive Layout**: Improved top bar and filter row wrapping on small screens and mobile viewports.

## 0.1.0

- Initial standalone release of `fitgrid_plus`.
- Integrated low-level high-performance canvas table virtualization engine (`fitgrid_table`).
- Added DevExtreme-style editing suite: inline cell editing, inline row editing, and modal form popup dialogs with validation and lifecycle hooks.
- Added Dynamic Pivot Grids with banded column headers, tree grouping, and moveable canvas split charts (grouped bar, column, line trend, donut).
- Added multi-level hierarchical grouping with draggable chip panel.
- Added pure Dart Excel (.xlsx), CSV, TSV, and JSON import and export.
- Added responsive Mobile Card / Feed view with swipe actions.
- Added rectangular cell range selection with instant statistical summaries (Count, Sum, Avg, Min, Max) and clipboard TSV copy.
- Added conditional formatting (data bars, color scale heatmaps, cell highlight badges, row colors).
- Added deterministic data quality auditor and 1-click anomaly cleaner.
- Added SharedPreferences layout and settings persistence.
- Zero AI/LLM/MCP overhead.
