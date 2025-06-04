import 'package:flutter/material.dart';
import 'package:flutter_application_4/main.dart'; // Assuming MyHomePage is in main.dart
import 'package:flutter_application_4/number_game_screen.dart'; // Will be used by challenge mode later
import 'package:flutter_application_4/challenge_mode_screen.dart'; // Import ChallengeModeScreen

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择游戏模式')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Navigate to Training Mode (existing MyHomePage)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(title: '训练模式'),
                  ), // Navigate to MyHomePage for level selection
                );
              },
              child: const Text('训练模式'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Challenge Mode
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChallengeModeScreen(),
                  ),
                );
              },
              child: const Text('挑战模式'),
            ),
          ],
        ),
      ),
    );
  }
}
