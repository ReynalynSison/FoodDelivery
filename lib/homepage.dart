import 'package:flutter/cupertino.dart';
import 'errands.dart';
import 'settings.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(tabBar: CupertinoTabBar(items: [
      BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.home), label: 'Errands'),
      BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.settings), label: 'Settings'),
    ]), tabBuilder: (context, index) {
      if (index == 0) {
        return Errands();
      } else {
        return Settings();
      }
    });
  }
}
