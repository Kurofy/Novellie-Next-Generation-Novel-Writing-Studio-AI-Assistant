import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/novel_export_service.dart';

final novelExportServiceProvider = Provider<NovelExportService>((ref) {
  return NovelExportService();
});
