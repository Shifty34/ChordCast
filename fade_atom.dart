import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';

class FadeAtom extends StatelessWidget {
  final Duration? delay;
  final Widget child;
  final bool withMovement;
  const FadeAtom(
      {Key? key, required this.child, this.delay, this.withMovement = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Duration _delay = (delay == null) ? Duration.zero : delay!;

    return DelayedDisplay(
      delay: _delay,
      child: child,
      slidingBeginOffset: (withMovement) ? Offset(0.0, 0.35) : Offset(0.0, 0),
    );
  }
}
