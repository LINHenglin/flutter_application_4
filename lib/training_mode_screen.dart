import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';
import 'sound_manager.dart';

class TrainingModeScreen extends StatefulWidget {
  final int gridSize;
  const TrainingModeScreen({Key? key, this.gridSize = 3}) : super(key: key);

  @override
  _TrainingModeScreenState createState() => _TrainingModeScreenState();
}

class _TrainingModeScreenState extends State<TrainingModeScreen> {
  Timer? _timer;
  Timer? _countdownTimer;
  int _elapsedTime = 0;
  bool _isGameOver = false;
  Set<int> _clickedNumbers = {};
  int _currentNumber = 1;
  List<int> _gridNumbers = [];
  Map<int, Color> _buttonColors = {};
  bool _isCountingDown = true;
  int _countdown = 3;
  final SoundManager _soundManager = SoundManager();

  final Color _defaultButtonColor = Colors.blue;
  final Color _correctButtonColor = Colors.green;
  final Color _incorrectButtonColor = Colors.red;

  @override
  void initState() {
    super.initState();
    debugPrint('初始化训练模式...');
    _soundManager.initialize();
    _initializeGame();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _soundManager.dispose();
    super.dispose();
  }

  void _startCountdown() {
    debugPrint('开始倒计时...');
    _countdown = 3;
    _isCountingDown = true;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      debugPrint('倒计时: $_countdown');
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          debugPrint('倒计时结束，开始游戏');
          timer.cancel();
          _isCountingDown = false;
          _startTimer();
        }
      });
    });
  }

  void _startTimer() {
    debugPrint('开始游戏计时');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _initializeGame() {
    final totalNumbers = widget.gridSize * widget.gridSize;
    final random = Random();
    List<int> numbersPool = List.generate(totalNumbers, (index) => index + 1);
    numbersPool.shuffle(random);
    _gridNumbers = numbersPool;

    _clickedNumbers.clear();
    _currentNumber = 1;
    _elapsedTime = 0;
    _isGameOver = false;

    _buttonColors = Map.fromIterable(
      _gridNumbers,
      key: (number) => number,
      value: (number) => _defaultButtonColor,
    );
  }

  void _handleNumberClick(int clickedNumber) async {
    if (_isGameOver || _isCountingDown) return;

    await _soundManager.playClickSound();
    if (!kIsWeb && (await Vibration.hasVibrator() ?? false)) {
      Vibration.vibrate(duration: 50);
    }

    if (clickedNumber == _currentNumber) {
      setState(() {
        _buttonColors[clickedNumber] = _correctButtonColor;
        _clickedNumbers.add(clickedNumber);
        _currentNumber++;

        if (_currentNumber > widget.gridSize * widget.gridSize) {
          _isGameOver = true;
          _stopTimer();
          _showWinDialog();
        }
      });
    } else {
      setState(() {
        _buttonColors[clickedNumber] = _incorrectButtonColor;
      });
      Timer(const Duration(milliseconds: 300), () {
        setState(() {
          if (_buttonColors[clickedNumber] != _correctButtonColor) {
            _buttonColors[clickedNumber] = _defaultButtonColor;
          }
        });
      });
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('恭喜！'),
          content: Text('你完成了训练！\n用时: $_elapsedTime 秒'),
          actions: <Widget>[
            TextButton(
              child: const Text('重新开始'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _initializeGame();
                  _startCountdown();
                });
              },
            ),
            TextButton(
              child: const Text('返回选择'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练模式')),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    '用时: $_elapsedTime 秒',
                    style: const TextStyle(fontSize: 24),
                  ),
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
                  itemCount: widget.gridSize * widget.gridSize,
                  itemBuilder: (context, index) {
                    final number = _gridNumbers[index];
                    final bool isClicked = _clickedNumbers.contains(number);

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
                        splashFactory:
                            isClicked ? NoSplash.splashFactory : null,
                      ),
                      onPressed: _isGameOver || _isCountingDown
                          ? null
                          : () => _handleNumberClick(number),
                      child:
                          Text('$number', style: TextStyle(fontSize: fontSize)),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isCountingDown)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
