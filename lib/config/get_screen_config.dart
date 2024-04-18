import 'package:dilalquran/modules/presentations/screens/home_screen.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:get/get.dart';

List<GetPage<dynamic>>? getPages = [
  GetPage(
    name: RouteScreen.home,
    page: () => const HomeScreen(),
  )
];
