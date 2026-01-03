import 'dart:async';

import 'package:flutter/material.dart';

class PreparationTimer extends StatefulWidget {
  final DateTime startAt; // use preparation_started_at
  final int preparationTime; // in minutes

  const PreparationTimer({
    super.key,
    required this.startAt,
    required this.preparationTime,
  });

  @override
  State<PreparationTimer> createState() => _PreparationTimerState();
}

class _PreparationTimerState extends State<PreparationTimer> {
  late Timer _timer;
  late DateTime _endTime;
  Duration _diff = Duration.zero;

  @override
  void initState() {
    super.initState();
    _endTime = widget.startAt.add(Duration(minutes: widget.preparationTime));
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _diff = _endTime.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _diff.isNegative ? _diff.abs() : _diff;
    final minutes =
        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Row(
      children: [
        Text(
          _diff.isNegative
              ? "متأخر: -$minutes:$seconds"
              : "ينتهي خلال: $minutes:$seconds",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: _diff.isNegative ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }
}
