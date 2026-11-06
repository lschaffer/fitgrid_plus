import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Base repository URL for source links.
const String kFitGridPlusRepoUrl = 'https://github.com/lschaffer/fitgrid_plus';

/// Launches a source URL in an external browser tab.
Future<void> launchSourceUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Convenience widget providing a standardized "Source Code" button.
class ExampleSourceButton extends StatelessWidget {
  final String relativeFilePath;
  final String label;
  final bool compact;

  const ExampleSourceButton({
    super.key,
    required this.relativeFilePath,
    this.label = 'Source Code',
    this.compact = false,
  });

  String get fullUrl => '$kFitGridPlusRepoUrl/blob/main/$relativeFilePath';

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: const Icon(Icons.code_rounded, size: 18),
        tooltip: 'View Source: $relativeFilePath',
        onPressed: () => launchSourceUrl(fullUrl),
      );
    }

    return FilledButton.tonalIcon(
      icon: const Icon(Icons.code_rounded, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      onPressed: () => launchSourceUrl(fullUrl),
    );
  }
}
