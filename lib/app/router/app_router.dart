import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/ai/presentation/screens/ai_chat_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/manuscript/presentation/screens/chapter_editor_screen.dart';
import '../../features/manuscript/presentation/screens/version_history_screen.dart';
import '../../features/manuscript/presentation/screens/zen_mode_screen.dart';
import '../../features/novels/presentation/screens/create_novel_screen.dart';
import '../../features/novels/presentation/screens/novel_library_screen.dart';
import '../../features/novels/presentation/screens/novel_workspace_screen.dart';
import '../../features/outline/presentation/screens/planning_hub_screen.dart';
import '../../features/settings/presentation/screens/more_menu_screen.dart';
import '../../features/tools/presentation/screens/family_tree_screen.dart';
import '../../features/tools/presentation/screens/mind_map_screen.dart';
import '../../features/tools/presentation/screens/name_generator_screen.dart';
import '../../features/tools/presentation/screens/tools_hub_screen.dart';
import '../../features/tools/presentation/screens/world_atlas_screen.dart';
import 'routes.dart';

import 'shell_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.home,
  routes: [
    // Modal & Fullscreen Routes (Outside Shell)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: Routes.createNovel,
      builder: (context, state) => const CreateNovelScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/novels/:id',
      builder: (context, state) => NovelWorkspaceScreen(
        novelId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/novels/:novelId/chapters/:chapterId',
      builder: (context, state) => ChapterEditorScreen(
        novelId: state.pathParameters['novelId']!,
        chapterId: state.pathParameters['chapterId']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/novels/:novelId/chapters/:chapterId/zen',
      builder: (context, state) => ZenModeScreen(
        novelId: state.pathParameters['novelId']!,
        chapterId: state.pathParameters['chapterId']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/novels/:novelId/chapters/:chapterId/history',
      builder: (context, state) => VersionHistoryScreen(
        novelId: state.pathParameters['novelId']!,
        chapterId: state.pathParameters['chapterId']!,
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: Routes.nameGenerator,
      builder: (context, state) => const NameGeneratorScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: Routes.mindMap,
      builder: (context, state) {
        final novelId = state.uri.queryParameters['novelId'];
        return MindMapScreen(initialNovelId: novelId);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: Routes.familyTree,
      builder: (context, state) {
        final novelId = state.uri.queryParameters['novelId'];
        return FamilyTreeScreen(initialNovelId: novelId);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: Routes.worldAtlas,
      builder: (context, state) {
        final novelId = state.uri.queryParameters['novelId'];
        return WorldAtlasScreen(initialNovelId: novelId);
      },
    ),

    // Main 6-Tab Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 2: Novels
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.novels,
              builder: (context, state) => const NovelLibraryScreen(),
            ),
          ],
        ),
        // Tab 3: Planning
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.planning,
              builder: (context, state) => const PlanningHubScreen(),
            ),
          ],
        ),
        // Tab 4: Tools
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.tools,
              builder: (context, state) => const ToolsHubScreen(),
            ),
          ],
        ),
        // Tab 5: AI
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.ai,
              builder: (context, state) => const AiChatScreen(),
            ),
          ],
        ),

        // Tab 5: More
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.more,
              builder: (context, state) => const MoreMenuScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
