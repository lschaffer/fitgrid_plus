# FitGrid Plus Showcase Gallery

A comprehensive showcase application demonstrating the enterprise capabilities of **FitGrid Plus** (`fitgrid_plus`), a high-performance virtualized Flutter DataGrid built for desktop, web, and mobile.

---

## Running the Showcase

Ensure you have Flutter `>=3.47.0` installed:

```bash
cd example
flutter pub get
flutter run -d windows   # or -d macos, -d linux, -d chrome
```

---

## Showcase Demos

The example application includes a responsive sidebar navigation (with hamburger menu collapse) containing 8 enterprise showcase modules:

### 1. Flagship Superstore Enterprise Grid
- **DevExtreme-Style Editing Lifecycle**: Switch dynamically between `Cell Inline`, `Row Inline`, and `Modal Popup Form` editing modes.
- **Dynamic Banded Pivot Matrix**: Drag-and-drop pivot engine aggregating multi-level rows and column groups.
- **Multi-Level Hierarchical Grouping**: Group rows by `Region`, `Category`, or any column with interactive drag chips.
- **Moveable Split Canvas Charts**: Real-time linked data visualizations (Bar, Column, Line Trend, Pie).
- **Pure-Dart Excel (.xlsx) Export**: Instant workbook generation without native bridges.

### 2. Feature 1: Conditional Formatting & Visuals
- In-cell horizontal **Data Bars** representing volume metrics.
- In-cell canvas **Sparklines** rendering 6-month historical trends.
- **Loss / Profit Highlighting**: Red negative values and custom row tinting.
- Interactive toggle chips to test visual customizations in real time.

### 3. Feature 2: Range Selection & Copy/Paste
- Excel-like contiguous rectangle drag selection.
- Live summary footer calculating `Sum`, `Average`, `Min`, `Max`, and `Count`.
- Clipboard integration with TSV copying for pasting into Excel or Google Sheets.

### 4. Feature 3: Master-Detail Child Rows
- Expandable hierarchical rows displaying nested orders and sub-line item grids.
- Independent column formatting, scrolling, and sizing in nested detail grids.

### 5. Feature 4: Dynamic Ingestion DataGrid
- Ingest datasets on-the-fly from CSV, TSV, Markdown tables, and structured YAML.
- Schema persistence and column metadata manager dialogs.
- Includes sample files in `sample_data/` (`sample_dataset.yaml` and `sample_dataset.md`).

### 6. Feature 5: Pure-Dart Excel (.xlsx) Ingestion
- Upload or inspect multi-sheet Microsoft Excel workbooks entirely in pure Dart.
- Automatic header discovery and column type inference.

### 7. Feature 6: Data Auditor & Cleaner
- Deterministic data quality auditing detecting type anomalies, null values, and statistical outliers.
- One-click remediation dialog cleaning datasets without external server dependencies.

### 8. Feature 7: Mobile Card / Feed View
- Single-tap responsive switch between standard DataGrid and card/feed presentation.
- Optimized for narrow smartphone and tablet screens.

---

## Sample Data Files

Sample files for ingestion testing are available in the [`sample_data/`](sample_data/) directory:
- [`sample_dataset.yaml`](sample_data/sample_dataset.yaml) - Structured YAML datacenter fleet metrics.
- [`sample_dataset.md`](sample_data/sample_dataset.md) - Markdown table format dataset.
