import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class TrainingModeScreen extends StatefulWidget {
  final int gridSize;

  const TrainingModeScreen({Key? key, required this.gridSize})
    : super(key: key);

  @override
  _TrainingModeScreenState createState() => _TrainingModeScreenState();
}

class _TrainingModeScreenState extends State<TrainingModeScreen> {
  List<int> _gridNumbers = []; // Numbers displayed on the grid
  int _nextNumberToClick = 1; // The next number the user needs to click
  Map<int, Color> _buttonColors = {}; // To store the color of each button

  Timer? _timer;
  int _elapsedTime = 0;
  bool _gameOver = false;

  late int _totalNumbers;

  final Color _defaultButtonColor = Colors.blue;
  final Color _correctButtonColor = Colors.green;
  final Color _incorrectButtonColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _totalNumbers = widget.gridSize * widget.gridSize;
    _initializeGame();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    _timer?.cancel();
    _elapsedTime = 0;
    _gameOver = false;

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

    _buttonColors = Map.fromIterable(
      _gridNumbers,
      key: (number) => number,
      value: (number) => _defaultButtonColor,
    );

    _nextNumberToClick = 1;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _handleButtonClick(int clickedNumber) {
    if (_gameOver) return;

    if (clickedNumber == _nextNumberToClick) {
      setState(() {
        _buttonColors[clickedNumber] = _correctButtonColor;
        _nextNumberToClick++;
        if (_nextNumberToClick > _totalNumbers) {
          _gameOver = true;
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
          content: Text('你成功按顺序点击了所有数字！\n用时: $_elapsedTime 秒'),
          actions: <Widget>[
            TextButton(
              child: const Text('再玩一次'),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
                _startTimer();
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
      appBar: AppBar(
        title: Text('训练模式: ${widget.gridSize}x${widget.gridSize}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  '时间: $_elapsedTime 秒',
                  style: const TextStyle(fontSize: 20),
                ),
                const Text('请按顺序点击以下数字', style: TextStyle(fontSize: 20)),
                if (_gameOver && _nextNumberToClick > _totalNumbers)
                  const Text(
                    '完成！',
                    style: TextStyle(
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
                final bool isDisabled = _gameOver;

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
                        _buttonColors[number] == _correctButtonColor
                            ? NoSplash.splashFactory
                            : null,
                  ),
                  onPressed:
                      isDisabled ? null : () => _handleButtonClick(number),
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
