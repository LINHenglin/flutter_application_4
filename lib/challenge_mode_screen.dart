import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:vibration/vibration.dart';
import 'sound_manager.dart';

class ChallengeModeScreen extends StatefulWidget {
  const ChallengeModeScreen({super.key});

  @override
  _ChallengeModeScreenState createState() => _ChallengeModeScreenState();
}

class _ChallengeModeScreenState extends State<ChallengeModeScreen> {
  Timer? _timer;
  int _totalElapsedTime = 0;
  int _currentLevel = 0;
  bool _isGameOver = false;
  final Set<int> _clickedNumbers = {};
  int _currentNumber = 1;
  List<int> _gridNumbers = [];
  Map<int, Color> _buttonColors = {}; // 添加按钮颜色映射
  final SoundManager _soundManager = SoundManager();

  // 关卡配置：从2x2开始，每关增加一个维度
  final List<int> _levelGridSizes = [2, 3, 4, 5];

  final Color _defaultButtonColor = Colors.blue;
  final Color _correctButtonColor = Colors.green;
  final Color _incorrectButtonColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeLevel();
    _soundManager.initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _soundManager.dispose();
    super.dispose();
  }

  void _startTimer() {
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
    _buttonColors = {
      for (var number in _gridNumbers) number: _defaultButtonColor
    };
  }

  void _handleNumberClick(int clickedNumber) async {
    if (_isGameOver) return;

    // 播放音效和震动
    await _soundManager.playClickSound();
    if (await Vibration.hasVibrator() ?? false) {
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
      body: Column(
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
                    splashFactory: isClicked ? NoSplash.splashFactory : null,
                  ),
                  onPressed:
                      _isGameOver ? null : () => _handleNumberClick(number),
                  child: Text('$number', style: TextStyle(fontSize: fontSize)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
