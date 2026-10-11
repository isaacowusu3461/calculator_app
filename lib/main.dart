
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

// Evaluates expressions using conventional operator precedence.
class ExpressionParser {
  ExpressionParser(String expression)
      : _input = expression
            .replaceAll('×', '*')
            .replaceAll('÷', '/')
            .replaceAll('−', '-');

  final String _input;
  int _position = 0;

  double parse() {
    final result = _parseExpression();
    _skipSpaces();

    if (_position != _input.length) {
      throw const FormatException('Invalid expression');
    }

    if (!result.isFinite) {
      throw const FormatException('Invalid result');
    }

    return result;
  }

  // Addition and subtraction.
  double _parseExpression() {
    var value = _parseTerm();

    while (true) {
      _skipSpaces();

      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  // Multiplication and division have higher precedence.
  double _parseTerm() {
    var value = _parseUnary();

    while (true) {
      _skipSpaces();

      if (_match('*')) {
        value *= _parseUnary();
      } else if (_match('/')) {
        final divisor = _parseUnary();

        if (divisor == 0) {
          throw const FormatException('Cannot divide by zero');
        }

        value /= divisor;
      } else {
        return value;
      }
    }
  }

  // Handles unary positive and negative signs.
  double _parseUnary() {
    _skipSpaces();

    if (_match('+')) {
      return _parseUnary();
    }

    if (_match('-')) {
      return -_parseUnary();
    }

    return _parsePrimary();
  }

  // Handles numbers and expressions inside parentheses.
  double _parsePrimary() {
    _skipSpaces();

    if (_match('(')) {
      final value = _parseExpression();
      _skipSpaces();

      if (!_match(')')) {
        throw const FormatException('Missing closing parenthesis');
      }

      return value;
    }

    return _parseNumber();
  }

  double _parseNumber() {
    _skipSpaces();
    final start = _position;
    bool hasDigit = false;
    bool hasDecimal = false;

    while (_position < _input.length) {
      final character = _input[_position];

      // Dart does not support >= or <= comparisons on Strings.
      if (RegExp(r'^[0-9]$').hasMatch(character)) {
        hasDigit = true;
        _position++;
      } else if (character == '.' && !hasDecimal) {
        hasDecimal = true;
        _position++;
      } else {
        break;
      }
    }

    if (!hasDigit) {
      throw const FormatException('Expected a number');
    }

    final number = double.tryParse(_input.substring(start, _position));

    if (number == null || !number.isFinite) {
      throw const FormatException('Invalid number');
    }

    return number;
  }

  bool _match(String character) {
    if (_position < _input.length &&
        _input[_position] == character) {
      _position++;
      return true;
    }

    return false;
  }

  void _skipSpaces() {
    while (_position < _input.length &&
        _input[_position].trim().isEmpty) {
      _position++;
    }
  }
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF151515),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  String? _pendingOperator;

  double _accumulator = 0;
  bool _newNumber = true;
  bool _standardMode = false;

  final List<String> _history = [];

  String _formatNumber(double value) {
    if (!value.isFinite) {
      return 'Error';
    }

    if (value.abs() < 1e-10) {
      value = 0;
    }

    if (value.abs() >= 1e12 ||
        (value != 0 && value.abs() < 1e-8)) {
      return value.toStringAsExponential(6);
    }

    String result = value.toStringAsFixed(10);

    if (result.contains('.')) {
      result = result.replaceFirst(RegExp(r'0+$'), '');
      result = result.replaceFirst(RegExp(r'\.$'), '');
    }

    return result;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetCalculator() {
    setState(() {
      _display = '0';
      _expression = '';
      _pendingOperator = null;
      _accumulator = 0;
      _newNumber = true;
    });
  }

  void _changeMode(bool standardMode) {
    setState(() {
      _standardMode = standardMode;
      _display = '0';
      _expression = '';
      _pendingOperator = null;
      _accumulator = 0;
      _newNumber = true;
    });
  }

  void _enterDigit(String digit) {
    setState(() {
      if (_standardMode) {
        _enterStandardDigit(digit);
      } else {
        if (_newNumber || _display == '0' || _display == 'Error') {
          _display = digit;
        } else if (_display.length < 16) {
          _display += digit;
        }

        _newNumber = false;
      }
    });
  }

  void _enterDecimal() {
    setState(() {
      if (_standardMode) {
        if (_expression.isNotEmpty &&
            _expression.endsWith(')')) {
          _expression += '×0.';
        } else if (_expression.isEmpty ||
            _endsWithOperatorOrOpenParenthesis(_expression)) {
          _expression += '0.';
        } else {
          final lastNumber =
              RegExp(r'\d+\.?\d*|\.\d+$').firstMatch(_expression);

          if (lastNumber == null ||
              !lastNumber.group(0)!.contains('.')) {
            _expression += '.';
          }
        }

        _updateStandardDisplay();
      } else {
        if (_newNumber || _display == 'Error') {
          _display = '0.';
        } else if (!_display.contains('.')) {
          _display += '.';
        }

        _newNumber = false;
      }
    });
  }

  void _enterStandardDigit(String digit) {
    if (_expression.endsWith(')')) {
      _expression += '×';
    }

    if (_expression.isNotEmpty &&
        _expression.endsWith('0') &&
        _expression.length > 1 &&
        RegExp(r'[+\-×÷(]0$').hasMatch(_expression)) {
      _expression = _expression.substring(0, _expression.length - 1);
    }

    _expression += digit;
    _updateStandardDisplay();
  }

  bool _endsWithOperatorOrOpenParenthesis(String expression) {
    return expression.endsWith('+') ||
        expression.endsWith('−') ||
        expression.endsWith('×') ||
        expression.endsWith('÷') ||
        expression.endsWith('(');
  }

  void _updateStandardDisplay() {
    final match = RegExp(r'\d+\.?\d*|\.\d+$').firstMatch(_expression);

    if (match != null) {
      _display = match.group(0)!;
    } else if (_expression.endsWith(')')) {
      _display = ')';
    } else if (_expression.isEmpty) {
      _display = '0';
    } else {
      _display = _expression;
    }
  }

  void _enterOperator(String operator) {
    setState(() {
      if (_standardMode) {
        _enterStandardOperator(operator);
      } else {
        _enterLeftToRightOperator(operator);
      }
    });
  }

  void _enterLeftToRightOperator(String operator) {
    final current = double.tryParse(_display);

    if (current == null) {
      return;
    }

    if (_pendingOperator != null && !_newNumber) {
      _accumulator = _calculate(
        _accumulator,
        current,
        _pendingOperator!,
      );
      _display = _formatNumber(_accumulator);
    } else if (_pendingOperator == null) {
      _accumulator = current;
    }

    _pendingOperator = operator;
    _expression = '${_display} $operator ';
    _newNumber = true;
  }

  void _enterStandardOperator(String operator) {
    if (_expression.isEmpty) {
      if (operator == '−') {
        _expression = '−';
      }
      return;
    }

    if (_expression.endsWith('(')) {
      if (operator == '−') {
        _expression += operator;
      }
      return;
    }

    if (_endsWithOperatorOrOpenParenthesis(_expression)) {
      _expression =
          _expression.substring(0, _expression.length - 1) + operator;
    } else {
      _expression += operator;
    }

    _updateStandardDisplay();
  }

  double _calculate(double first, double second, String operator) {
    switch (operator) {
      case '+':
        return first + second;
      case '−':
        return first - second;
      case '×':
        return first * second;
      case '÷':
        if (second == 0) {
          throw const FormatException('Cannot divide by zero');
        }
        return first / second;
      default:
        return second;
    }
  }

  void _calculateResult() {
    try {
      setState(() {
        if (_standardMode) {
          if (_expression.isEmpty) {
            return;
          }

          final result = ExpressionParser(_expression).parse();
          _history.insert(0, '$_expression = ${_formatNumber(result)}');
          _display = _formatNumber(result);
          _expression = '';
          _newNumber = true;
        } else {
          if (_pendingOperator == null) {
            return;
          }

          final second = double.tryParse(_display);

          if (second == null) {
            return;
          }

          final original =
              '${_formatNumber(_accumulator)} $_pendingOperator ${_formatNumber(second)}';

          final result = _calculate(
            _accumulator,
            second,
            _pendingOperator!,
          );

          _history.insert(0, '$original = ${_formatNumber(result)}');
          _display = _formatNumber(result);
          _accumulator = result;
          _pendingOperator = null;
          _expression = '';
          _newNumber = true;
        }
      });
    } on FormatException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to calculate this expression.');
    }
  }

  void _enterParenthesis(String parenthesis) {
    if (!_standardMode) {
      _showError('Parentheses are available in Standard mode.');
      return;
    }

    setState(() {
      if (parenthesis == '(') {
        if (_expression.isNotEmpty &&
            (_expression.endsWith(')') ||
                RegExp(r'\d$').hasMatch(_expression))) {
          _expression += '×';
        }
        _expression += '(';
      } else {
        final openCount = '('.allMatches(_expression).length;
        final closeCount = ')'.allMatches(_expression).length;

        if (openCount > closeCount &&
            _expression.isNotEmpty &&
            !_endsWithOperatorOrOpenParenthesis(_expression)) {
          _expression += ')';
        }
      }

      _updateStandardDisplay();
    });
  }

  void _toggleSign() {
    setState(() {
      if (_standardMode) {
        final match =
            RegExp(r'\d+\.?\d*|\.\d+$').firstMatch(_expression);

        if (match == null) {
          if (_expression.isEmpty) {
            _expression = '−';
          }
          return;
        }

        final start = match.start;
        final number = match.group(0)!;
        final before = _expression.substring(0, start);

        if (before.endsWith('−') &&
            (before.length == 1 ||
                '+×÷(−'.contains(before[before.length - 2]))) {
          _expression =
              before.substring(0, before.length - 1) + number;
        } else if (before.isEmpty ||
            '+×÷(−'.contains(before[before.length - 1])) {
          _expression = '$before−$number';
        } else {
          _expression = '$before−$number';
        }

        _updateStandardDisplay();
      } else {
        final value = double.tryParse(_display);
        if (value != null) {
          _display = _formatNumber(-value);
          _newNumber = false;
        }
      }
    });
  }

  void _percentage() {
    setState(() {
      if (_standardMode) {
        final match =
            RegExp(r'\d+\.?\d*|\.\d+$').firstMatch(_expression);

        if (match == null) {
          return;
        }

        final value = double.parse(match.group(0)!) / 100;
        _expression = _expression.substring(0, match.start) +
            _formatNumber(value);
        _updateStandardDisplay();
      } else {
        final value = double.tryParse(_display);

        if (value != null) {
          _display = _formatNumber(value / 100);
          _newNumber = false;
        }
      }
    });
  }

  void _squareRoot() {
    setState(() {
      final value = double.tryParse(_display);

      if (value == null || value < 0) {
        _showError('Square root requires a non-negative number.');
        return;
      }

      final result = math.sqrt(value);

      if (_standardMode) {
        final match =
            RegExp(r'\d+\.?\d*|\.\d+$').firstMatch(_expression);

        if (match != null) {
          _expression = _expression.substring(0, match.start) +
              _formatNumber(result);
        } else if (_expression.isEmpty) {
          _expression = _formatNumber(result);
        }

        _updateStandardDisplay();
      } else {
        _display = _formatNumber(result);
        _newNumber = false;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_standardMode) {
        if (_expression.isNotEmpty) {
          _expression =
              _expression.substring(0, _expression.length - 1);
          _updateStandardDisplay();
        }
      } else if (!_newNumber && _display.length > 1) {
        _display = _display.substring(0, _display.length - 1);

        if (_display == '-') {
          _display = '0';
        }
      } else {
        _display = '0';
        _newNumber = true;
      }
    });
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF242424),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Calculation History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _history.isEmpty
                      ? const Center(child: Text('No calculations yet.'))
                      : ListView.builder(
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_history[index]),
                            );
                          },
                        ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _history.clear());
                    Navigator.pop(context);
                  },
                  child: const Text('Clear History'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(
    String label, {
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? foregroundColor,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 58,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  backgroundColor ?? const Color(0xFF303030),
              foregroundColor: foregroundColor ?? Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onTap,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<Widget> buttons) {
    return Row(
      children: buttons,
    );
  }

  Widget _buildKeypad() {
    final functionColor = const Color(0xFF454545);
    final operatorColor = Colors.deepPurple.shade700;

    return Column(
      children: [
        _buildRow([
          _buildButton('AC',
              onTap: _resetCalculator,
              backgroundColor: functionColor),
          _buildButton('⌫',
              onTap: _backspace,
              backgroundColor: functionColor),
          _buildButton('(', onTap: () => _enterParenthesis('('),
              backgroundColor: functionColor),
          _buildButton(')', onTap: () => _enterParenthesis(')'),
              backgroundColor: functionColor),
        ]),
        _buildRow([
          _buildButton('7', onTap: () => _enterDigit('7')),
          _buildButton('8', onTap: () => _enterDigit('8')),
          _buildButton('9', onTap: () => _enterDigit('9')),
          _buildButton('÷',
              onTap: () => _enterOperator('÷'),
              backgroundColor: operatorColor),
        ]),
        _buildRow([
          _buildButton('4', onTap: () => _enterDigit('4')),
          _buildButton('5', onTap: () => _enterDigit('5')),
          _buildButton('6', onTap: () => _enterDigit('6')),
          _buildButton('×',
              onTap: () => _enterOperator('×'),
              backgroundColor: operatorColor),
        ]),
        _buildRow([
          _buildButton('1', onTap: () => _enterDigit('1')),
          _buildButton('2', onTap: () => _enterDigit('2')),
          _buildButton('3', onTap: () => _enterDigit('3')),
          _buildButton('−',
              onTap: () => _enterOperator('−'),
              backgroundColor: operatorColor),
        ]),
        _buildRow([
          _buildButton('±',
              onTap: _toggleSign,
              backgroundColor: functionColor),
          _buildButton('0', onTap: () => _enterDigit('0')),
          _buildButton('.', onTap: _enterDecimal),
          _buildButton('+',
              onTap: () => _enterOperator('+'),
              backgroundColor: operatorColor),
        ]),
        _buildRow([
          _buildButton('%',
              onTap: _percentage,
              backgroundColor: functionColor),
          _buildButton('√',
              onTap: _squareRoot,
              backgroundColor: functionColor),
          _buildButton('=', onTap: _calculateResult,
              backgroundColor: Colors.deepPurple),
          _buildButton('',
              onTap: null,
              backgroundColor: Colors.transparent),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: const Color(0xFF151515),
        actions: [
          IconButton(
            tooltip: 'Calculation history',
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Left-to-Right'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Standard'),
                  ),
                ],
                selected: {_standardMode},
                onSelectionChanged: (selection) {
                  _changeMode(selection.first);
                },
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_standardMode && _expression.isNotEmpty)
                      Text(
                        _expression,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white60,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      _display,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _standardMode
                          ? 'Standard precedence: × and ÷ before + and −'
                          : 'Operations are evaluated left to right',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: _buildKeypad(),
            ),
          ],
        ),
      ),
    );
  }
}