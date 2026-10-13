import 'package:flutter/material.dart';
import 'today_screen.dart';
import 'log_screen.dart';
import 'insights_screen.dart';
import 'reminders_screen.dart';
import '../theme.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0; // 0 Today, 2 Insights, 3 Reminders (1 is Log, never selected)

  void _onTap(int i) {
    if (i == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LogScreen()),
      );
    } else {
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          SizedBox(), // Log opens as its own screen
          InsightsScreen(),
          RemindersScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        backgroundColor: context.card,
        indicatorColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            label: 'Reminders',
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
