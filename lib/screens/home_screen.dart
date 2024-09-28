import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);

    analyticsService.logScreenView('HomeScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Club'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${authService.currentUser?.displayName ?? 'User'}!'),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Start Workout'),
              onPressed: () {
                // TODO: Implement workout functionality
                analyticsService.logEvent('start_workout');
              },
            ),
          ],
        ),
      ),
    );
  }
}