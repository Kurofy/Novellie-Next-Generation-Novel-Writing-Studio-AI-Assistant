abstract final class Routes {
  static const home = '/home';
  static const novels = '/novels';
  static const planning = '/planning';
  static const tools = '/tools';
  static const ai = '/ai';
  static const more = '/more';

  // Tools routes
  static const nameGenerator = '/tools/name-generator';
  static const mindMap = '/tools/mind-map';
  static const familyTree = '/tools/family-tree';
  static const worldAtlas = '/tools/world-atlas';

  // Details & Nested routes
  static const onboarding = '/onboarding';
  static const createNovel = '/novels/new';
  static String novelWorkspace(String id) => '/novels/$id';
  static String chapterEditor(String novelId, String chapterId) =>
      '/novels/$novelId/chapters/$chapterId';
  static String zenMode(String novelId, String chapterId) =>
      '/novels/$novelId/chapters/$chapterId/zen';
  static String versionHistory(String novelId, String chapterId) =>
      '/novels/$novelId/chapters/$chapterId/history';
}
