import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';
import 'sound_manager.dart';

class ChallengeModeScreen extends StatefulWidget {
  const ChallengeModeScreen({Key? key}) : super(key: key);

  @override
  _ChallengeModeScreenState createState() => _ChallengeModeScreenState();
}

class _ChallengeModeScreenState extends State<ChallengeModeScreen> {
  Timer? _timer;
  Timer? _countdownTimer;
  int _totalElapsedTime = 0;
  int _currentLevel = 0;
  bool _isGameOver = false;
  Set<int> _clickedNumbers = {};
  int _currentNumber = 1;
  List<int> _gridNumbers = [];
  Map<int, Color> _buttonColors = {};
  bool _isCountingDown = true;
  int _countdown = 3;
  final SoundManager _soundManager = SoundManager();

  // 关卡配置：从2x2开始，每关增加一个维度
  final List<int> _levelGridSizes = [2, 3, 4, 5];

  final Color _defaultButtonColor = Colors.blue;
  final Color _correctButtonColor = Colors.green;
  final Color _incorrectButtonColor = Colors.red;

  @override
  void initState() {
    super.initState();
    debugPrint('初始化游戏...');
    _soundManager.initialize();
    _initializeLevel();
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

    // 取消之前的计时器
    _countdownTimer?.cancel();

    // 创建新的计时器
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
        _totalElapsedTime++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _initializeLevel() {
    final currentGridSize = _levelGridSizes[_currentLevel];
    final totalNumbers = currentGridSize * currentGridSize;

    // 生成并打乱数字
    final random = Random();
    List<int> numbersPool = List.generate(totalNumbers, (index) => index + 1);
    numbersPool.shuffle(random);
    _gridNumbers = numbersPool;

    // 重置游戏状态
    _clickedNumbers.clear();
    _currentNumber = 1;

    // 初始化按钮颜色
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

        // 检查当前关卡是否完成
        final currentGridSize = _levelGridSizes[_currentLevel];
        final totalNumbers = currentGridSize * currentGridSize;

        if (_currentNumber > totalNumbers) {
          // 当前关卡完成，进入下一关
          _currentLevel++;
          if (_currentLevel >= _levelGridSizes.length) {
            // 所有关卡完成
            _isGameOver = true;
            _stopTimer();
            _showWinDialog();
          } else {
            // 初始化下一关
            _initializeLevel();
          }
        }
      });
    } else {
      // 点击错误，显示红色反馈
      setState(() {
        _buttonColors[clickedNumber] = _incorrectButtonColor;
      });
      // 300毫秒后恢复原色
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
          content: Text('你成功完成了所有关卡！\n总用时: $_totalElapsedTime 秒'),
          actions: <Widget>[
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

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('游戏结束'),
          content: Text('点击错误！\n总用时: $_totalElapsedTime 秒'),
          actions: <Widget>[
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

  @override
  Widget build(BuildContext context) {
    if (_currentLevel >= _levelGridSizes.length) {
      return const Scaffold(body: Center(child: Text('游戏完成！')));
    }

    final currentGridSize = _levelGridSizes[_currentLevel];
    final totalNumbers = currentGridSize * currentGridSize;

    return Scaffold(
      appBar: AppBar(title: const Text('挑战模式')),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    '总时间: $_totalElapsedTime 秒',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: currentGridSize,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: totalNumbers,
                  itemBuilder: (context, index) {
                    final number = _gridNumbers[index];
                    final bool isClicked = _clickedNumbers.contains(number);

                    double fontSize = 24;
                    if (currentGridSize >= 4) {
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
