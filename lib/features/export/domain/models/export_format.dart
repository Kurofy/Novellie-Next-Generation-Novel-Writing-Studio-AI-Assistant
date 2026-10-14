enum ExportFormat {
  markdown('Markdown (.md)', 'md', 'text/markdown'),
  txt('Plain Text (.txt)', 'txt', 'text/plain'),
  html('Web HTML (.html)', 'html', 'text/html');

  final String label;
  final String extension;
  final String mimeType;

  const ExportFormat(this.label, this.extension, this.mimeType);
}
