import 'package:flutter/material.dart';

import 'package:optimus_opost/Constants/constants.dart';

class ButtonWidget extends StatelessWidget {
  final name;
  Function OnClick;
  ButtonWidget({
    Key? key,
    required this.name,
    required this.OnClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        OnClick();
      },
      child: Container(
        width: double.infinity,
        height: 60,
        child: Center(
          child: Text(
            name,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: MAINCOLOR),
      ),
    );
  }
}
