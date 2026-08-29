import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/cafe/presentation/screens/cafe_screen.dart';
import '../../features/cafe/presentation/screens/shop_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/work_transition/presentation/screens/commute_result_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/cafe',
        builder: (context, state) => const CafeScreen(),
        routes: [
          GoRoute(path: 'shop', builder: (context, state) => const ShopScreen()),
          GoRoute(
            path: 'commute-result',
            builder: (context, state) => const CommuteResultScreen(),
          ),
        ],
      ),
    ],
  );
}
