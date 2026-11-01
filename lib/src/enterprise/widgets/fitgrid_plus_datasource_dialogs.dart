import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../config/fitgrid_plus_dynamic_storage.dart';
import '../controllers/fitgrid_plus_controller.dart';
import '../models/fitgrid_plus_dynamic_datasource.dart';

/// Modal dialog for browsing, loading, exporting, deleting, and importing dynamic DataGrid datasources.
class FitGridPlusDatasourceManagerDialog extends StatefulWidget {
  final FitGridPlusController controller;

  const FitGridPlusDatasourceManagerDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, FitGridPlusController controller) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => FitGridPlusDatasourceManagerDialog(controller: controller),
    );
  }

  @override
  State<FitGridPlusDatasourceManagerDialog> createState() =>
      _FitGridPlusDatasourceManagerDialogState();
}

class _FitGridPlusDatasourceManagerDialogState
    extends State<FitGridPlusDatasourceManagerDialog> {
  List<FitGridPlusDynamicDescriptor> _datasources = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() => _isLoading = true);
    final list = await FitGridPlusDynamicStorage.listDatasources();
    if (mounted) {
      setState(() {
        _datasources = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLoad(FitGridPlusDynamicDescriptor desc) async {
    final model = await FitGridPlusDynamicStorage.getModel(desc.name);
    final rows = await FitGridPlusDynamicStorage.getDataRows(desc.name);

    if (model != null && rows != null && mounted) {
      widget.controller.loadDynamicDatasource(desc, model.toColumns(), rows);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loaded datasource "${desc.title}" (${rows.length} rows)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleDelete(FitGridPlusDynamicDescriptor desc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Datasource'),
        content: Text(
          'Are you sure you want to delete "${desc.title}" (${desc.name})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FitGridPlusDynamicStorage.deleteDatasource(desc.name);
      await _loadList();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Deleted "${desc.name}"')));
      }
    }
  }

  Future<void> _handleExportYaml(FitGridPlusDynamicDescriptor desc) async {
    final yamlString = await FitGridPlusDynamicStorage.exportBundleYaml(desc.name);
    if (yamlString != null && mounted) {
      try {
        final bytes = utf8.encode(yamlString);
        String? savedPath;
        try {
          savedPath = await FileSaver.instance.saveAs(
            name: '${desc.name}.fitgrid',
            bytes: Uint8List.fromList(bytes),
            fileExtension: 'yaml',
            mimeType: MimeType.other,
            dialogTitle: 'Save Dynamic Grid YAML Bundle',
          );
        } catch (_) {
          savedPath = await FileSaver.instance.saveFile(
            name: '${desc.name}.fitgrid',
            fileExtension: 'yaml',
            bytes: Uint8List.fromList(bytes),
            mimeType: MimeType.other,
          );
        }
        if (mounted) {
          final msg = (savedPath != null && savedPath.isNotEmpty)
              ? 'Saved to: $savedPath'
              : 'Exported "${desc.name}" bundle as YAML.';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: yamlString));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied YAML bundle to clipboard.')),
          );
        }
      }
    }
  }

  Future<void> _handleImportYaml() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['yaml', 'yml', 'json', 'fitgrid', 'agrid'],
      );

      if (file != null) {
        final content = await file.xFile.readAsString();

        if (content.isNotEmpty) {
          final desc = await FitGridPlusDynamicStorage.importBundleYaml(content);
          await _loadList();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imported dynamic datasource "${desc.title}"!'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _handleImportExcel() async {
    try {
      final sheet = await widget.controller.importExcel(context: context);
      if (sheet != null) {
        await _loadList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported Excel worksheet "${sheet.name}"!'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeName = widget.controller.activeDynamicDatasource?.name;

    final filtered = _datasources.where((d) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return d.name.toLowerCase().contains(q) ||
          d.title.toLowerCase().contains(q) ||
          d.sourceType.toLowerCase().contains(q);
    }).toList();

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final bodyContent = Column(
      children: [
        // Search Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search datasources...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),

        // Body List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No saved dynamic datasources found.'
                            : 'No datasources match "$_searchQuery".',
                        style: TextStyle(color: theme.disabledColor),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final d = filtered[index];
                    final isActive = d.name == activeName;

                    return Card(
                      elevation: isActive ? 2 : 0,
                      color: isActive
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.3,
                            )
                          : (isDark
                                ? theme.colorScheme.surfaceContainerHighest
                                : Colors.grey.shade50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isActive
                              ? theme.colorScheme.primary
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade300),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          d.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isActive) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _chip(d.name, Colors.blueGrey),
                                      _chip('${d.rowCount} rows', Colors.teal),
                                      _chip(
                                        d.sourceType.toUpperCase(),
                                        Colors.indigo,
                                      ),
                                      if (d.isReadonly)
                                        _chip(
                                          'READ-ONLY',
                                          Colors.amber.shade900,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    size: 18,
                                  ),
                                  tooltip: 'Export YAML Bundle',
                                  onPressed: () => _handleExportYaml(d),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete Datasource',
                                  onPressed: () => _handleDelete(d),
                                ),
                                const SizedBox(width: 4),
                                FilledButton(
                                  onPressed: isActive
                                      ? null
                                      : () => _handleLoad(d),
                                  child: Text(isActive ? 'Current' : 'Load'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (isMobile) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Dynamic Datasources'),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_upload_outlined),
                tooltip: 'Import YAML',
                onPressed: _handleImportYaml,
              ),
            ],
          ),
          body: bodyContent,
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.table_view_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dynamic Datasources',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(
                      Icons.table_chart_rounded,
                      size: 16,
                      color: Color(0xFF107C41),
                    ),
                    label: const Text('Import Excel'),
                    onPressed: _handleImportExcel,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: const Text('Import YAML'),
                    onPressed: _handleImportYaml,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: bodyContent),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
