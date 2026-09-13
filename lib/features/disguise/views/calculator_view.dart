import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../controllers/disguise_controller.dart';

/// A working calculator that doubles as the way back into a disguised app.
///
/// It is not a thin cover: it adds, subtracts, multiplies and divides like the real thing,
/// because a "calculator" that does not calculate is the first thing someone poking at the
/// phone would notice. The way in is invisible on purpose — typing the Private space PIN and
/// pressing `=` opens the app instead of computing; anything else computes normally.
class CalculatorView extends StatefulWidget {
  const CalculatorView({required this.controller, super.key});

  final DisguiseController controller;

  @override
  State<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<CalculatorView> {
  String _entry = '0';
  String _history = '';
  double? _accumulator;
  String? _pendingOp;
  bool _fresh = true;

  bool get _hasOperator => _pendingOp != null;

  void _digit(String d) {
    setState(() {
      if (_fresh) {
        _entry = d;
        _fresh = false;
      } else {
        _entry = _entry == '0' ? d : '$_entry$d';
      }
    });
  }

  void _dot() {
    setState(() {
      if (_fresh) {
        _entry = '0.';
        _fresh = false;
      } else if (!_entry.contains('.')) {
        _entry = '$_entry.';
      }
    });
  }

  void _negate() {
    setState(() {
      if (_entry.startsWith('-')) {
        _entry = _entry.substring(1);
      } else if (_entry != '0') {
        _entry = '-$_entry';
      }
    });
  }

  void _operator(String op) {
    setState(() {
      final double value = double.tryParse(_entry) ?? 0;
      if (_hasOperator && !_fresh) {
        _accumulator = _apply(_accumulator ?? 0, _pendingOp!, value);
        _entry = _format(_accumulator!);
      } else {
        _accumulator = value;
      }
      _pendingOp = op;
      _history = '${_format(_accumulator ?? value)} $op';
      _fresh = true;
    });
  }

  Future<void> _equals() async {
    // The way in: a bare whole number that matches the PIN. Checked before any arithmetic,
    // and only when no operator has been keyed, so a computed result can never unlock it.
    final String entry = _entry;
    if (!_hasOperator && RegExp(r'^\d+$').hasMatch(entry)) {
      if (await widget.controller.unlock(entry)) {
        return; // the root swaps the calculator out for the app
      }
    }

    if (!_hasOperator) {
      return;
    }
    setState(() {
      final double result =
          _apply(_accumulator ?? 0, _pendingOp!, double.tryParse(entry) ?? 0);
      _entry = _format(result);
      _history = '';
      _accumulator = null;
      _pendingOp = null;
      _fresh = true;
    });
  }

  void _clear() {
    setState(() {
      _entry = '0';
      _history = '';
      _accumulator = null;
      _pendingOp = null;
      _fresh = true;
    });
  }

  void _backspace() {
    setState(() {
      if (_fresh || _entry.length <= 1) {
        _entry = '0';
        _fresh = true;
      } else {
        _entry = _entry.substring(0, _entry.length - 1);
      }
    });
  }

  double _apply(double a, String op, double b) => switch (op) {
        '+' => a + b,
        '−' => a - b,
        '×' => a * b,
        '÷' => b == 0 ? double.nan : a / b,
        _ => b,
      };

  String _format(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        _history,
                        style: const TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _entry,
                          key: const Key('calculator-display'),
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _keypad(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keypad(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          _row(<Widget>[
            _key('C', _clear, accent: true),
            _key('⌫', _backspace),
            _key('÷', () => _operator('÷')),
            _key('×', () => _operator('×')),
          ]),
          _row(<Widget>[
            _key('7', () => _digit('7')),
            _key('8', () => _digit('8')),
            _key('9', () => _digit('9')),
            _key('−', () => _operator('−')),
          ]),
          _row(<Widget>[
            _key('4', () => _digit('4')),
            _key('5', () => _digit('5')),
            _key('6', () => _digit('6')),
            _key('+', () => _operator('+')),
          ]),
          _row(<Widget>[
            _key('1', () => _digit('1')),
            _key('2', () => _digit('2')),
            _key('3', () => _digit('3')),
            _key('=', _equals, accent: true),
          ]),
          _row(<Widget>[
            _key('0', () => _digit('0'), flex: 2),
            _key('.', _dot),
            _key('±', _negate),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: children),
      );

  Widget _key(String label, VoidCallback onTap, {bool accent = false, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 64,
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: accent
                  ? AppTheme.accent
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: accent
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(label, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}
