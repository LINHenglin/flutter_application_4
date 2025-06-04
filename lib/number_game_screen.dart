import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class NumberGameScreen extends StatefulWidget {
  final int gridSize;
  // Removed onLevelComplete and onChallengeTimeout callbacks
  // Level logic will be handled by parent in challenge mode

  const NumberGameScreen({super.key, required this.gridSize});

  @override
  _NumberGameScreenState createState() => _NumberGameScreenState();
}

class _NumberGameScreenState extends State<NumberGameScreen> {
  List<int> _gridNumbers = []; // Numbers displayed on the grid
  int _nextNumberToClick = 1; // 添加这个变量
  Map<int, Color> _buttonColors = {}; // To store the color of each button

  // Use internal timer and elapsed time only for training mode
  Timer? _trainingTimer;
  int _trainingElapsedTime = 0;
  bool _trainingGameOver = false; // Separate flag for training mode game over

  late int _totalNumbers;

  final Color _defaultButtonColor = Colors.blue; // Default button color
  final Color _correctButtonColor = Colors.green; // Color for correct clicks
  final Color _incorrectButtonColor = Colors.red; // Color for incorrect clicks

  // Add variables for challenge mode state (managed by parent)
  int? _challengeCurrentNumber; // The number to click in challenge mode
  Set<int> _clickedNumbers =
      {}; // Keep track of clicked numbers in challenge mode
  bool _isChallengeMode = false; // Flag to indicate challenge mode

  @override
  void initState() {
    super.initState();
    _totalNumbers = widget.gridSize * widget.gridSize;
    // Determine mode based on whether callbacks were provided (removed callbacks)
    // _isChallengeMode = widget.onLevelComplete != null;
    // For now, assume training mode unless told otherwise by parent (will pass flag later)
    _isChallengeMode = false; // Set explicitly for now

    _initializeGame();
    if (!_isChallengeMode) {
      // Start timer only in training mode
      _startTrainingTimer();
    }
  }

  @override
  void dispose() {
    _trainingTimer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    _trainingTimer?.cancel(); // Cancel training timer on init
    _trainingElapsedTime = 0; // Reset elapsed time
    _trainingGameOver = false; // Reset training game over flag

    final random = Random();
    List<int> numbersPool;

    if (widget.gridSize == 2) {
      numbersPool = List.generate(4, (index) => index + 1);
    } else {
      numbersPool = List.generate(_totalNumbers, (index) => index + 1);
    }

    numbersPool.shuffle(random);
    _gridNumbers =
        numbersPool.take(min(_totalNumbers, numbersPool.length)).toList();
    _gridNumbers.shuffle(random);

    // Initialize button colors to default
    _buttonColors = {
      for (var number in _gridNumbers) number: _defaultButtonColor
    };

    _nextNumberToClick = 1; // 重置这个变量
    _clickedNumbers = {}; // Reset clicked numbers for challenge mode
  }

  void _startTrainingTimer() {
    _trainingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _trainingElapsedTime++;
        // Training mode specific time limit check (add if needed)
      });
    });
  }

  void _stopTrainingTimer() {
    _trainingTimer?.cancel();
  }

  void _handleButtonClick(int clickedNumber) {
    if (!_isChallengeMode && _trainingGameOver) {
      return; // Prevent clicks in training mode if game over
    }

    if (!_isChallengeMode) {
      // Training mode logic
      if (clickedNumber == _nextNumberToClick) {
        setState(() {
          _buttonColors[clickedNumber] = _correctButtonColor;
          _nextNumberToClick++;
          if (_nextNumberToClick > _totalNumbers) {
            _trainingGameOver = true;
            _stopTrainingTimer();
            _showWinDialog();
          }
        });
      } else {
        // Incorrect click: temporarily change button color to red
        setState(() {
          _buttonColors[clickedNumber] = _incorrectButtonColor;
        });
        // Revert color after a short delay
        Timer(const Duration(milliseconds: 300), () {
          setState(() {
            if (_buttonColors[clickedNumber] != _correctButtonColor) {
              _buttonColors[clickedNumber] = _defaultButtonColor;
            }
          });
        });
      }
    } else {
      // Challenge mode logic (simplified, parent will handle validation)
      // In challenge mode, just report the click to the parent
      // The parent (ChallengeModeScreen) will determine if it's correct and update the UI via state
      // Need to pass the clicked number back to the parent
      // This requires a callback to pass click events up

      // For now, just update local color for feedback, parent will overwrite
      setState(() {
        if (_clickedNumbers.contains(clickedNumber)) {
          return; // Ignore if already correctly clicked
        }

        if (clickedNumber == _challengeCurrentNumber) {
          // Correct click in challenge mode
          _buttonColors[clickedNumber] = _correctButtonColor;
          _clickedNumbers.add(clickedNumber);
          // Need to notify parent that this number was clicked correctly
          // This requires a callback like onNumberCorrectlyClicked
        } else {
          // Incorrect click in challenge mode
          _buttonColors[clickedNumber] = _incorrectButtonColor;
          Timer(const Duration(milliseconds: 300), () {
            setState(() {
              if (_buttonColors[clickedNumber] != _correctButtonColor) {
                _buttonColors[clickedNumber] = _defaultButtonColor;
              }
            });
          });
          // Need to notify parent of incorrect click
          // This requires a callback like onNumberIncorrectlyClicked
        }
      });
    }
  }

  void _showWinDialog() {
    // This dialog is only shown in training mode
    if (_isChallengeMode) return; // Only show in training mode

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('恭喜！'),
          content: Text(
            '你成功按顺序点击了所有数字！\n用时: $_trainingElapsedTime 秒',
          ), // Use training time
          actions: <Widget>[
            TextButton(
              child: const Text('再玩一次'),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
                _startTrainingTimer(); // Restart timer for next training game
              },
            ),
            TextButton(
              child: const Text('返回首页'),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to update challenge mode state from parent
  void updateChallengeState({
    required int currentNumber,
    required Set<int> clickedNumbers,
    required bool isChallengeMode,
  }) {
    setState(() {
      _isChallengeMode = isChallengeMode;
      _challengeCurrentNumber = currentNumber;
      _clickedNumbers = clickedNumbers; // Update clicked numbers set

      // Update button colors based on clicked numbers
      _buttonColors.forEach((number, color) {
        if (_clickedNumbers.contains(number)) {
          _buttonColors[number] =
              _correctButtonColor; // Set correctly clicked to green
        } else {
          _buttonColors[number] = _defaultButtonColor; // Others to default
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isChallengeMode
              ? '挑战模式'
              : '关卡: ${widget.gridSize}x${widget.gridSize}',
        ),
      ), // Display current mode or level
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 显示计时器 (only show in training mode)
                if (!_isChallengeMode) // Only show level timer in training mode
                  Text(
                    '时间: $_trainingElapsedTime 秒', // Display level elapsed time
                    style: const TextStyle(fontSize: 20),
                  ),

                // Challenge mode status display (will be updated by parent)
                if (_isChallengeMode &&
                    _challengeCurrentNumber !=
                        null) // Show current number to click in challenge mode
                  Text(
                    '点击数字: $_challengeCurrentNumber', // Display current number to click
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.blueAccent,
                    ),
                  )
                else if (_isChallengeMode && _challengeCurrentNumber == null)
                  const Text('挑战完成！'), // Challenge completed text
                // Display completion status if level is finished (in training mode win)
                if (!_isChallengeMode &&
                    _trainingGameOver &&
                    _nextNumberToClick > _totalNumbers)
                  Text(
                    '完成！',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.gridSize,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _gridNumbers.length,
              itemBuilder: (context, index) {
                final number = _gridNumbers[index];
                // Button is disabled if game is over (only win in training mode)
                // In challenge mode, buttons are enabled unless the challenge is over (handled externally)
                final bool isDisabled = !_isChallengeMode && _trainingGameOver;

                // Adjust font size based on grid size
                double fontSize = 24;
                if (widget.gridSize >= 4) {
                  fontSize = 18;
                }

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    backgroundColor: _buttonColors[number],
                    // Disable splash effect for already clicked correct numbers
                    splashFactory: _buttonColors[number] == _correctButtonColor
                        ? NoSplash.splashFactory
                        : null,
                  ),
                  onPressed: isDisabled
                      ? null
                      : () {
                          _handleButtonClick(number);
                        },
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: fontSize,
                    ), // Use dynamic fontSize
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
