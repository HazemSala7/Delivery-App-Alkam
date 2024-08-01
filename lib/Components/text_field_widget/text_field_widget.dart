import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:optimus_opost/Constants/constants.dart';

class TextFieldWidget extends StatelessWidget {
  TextEditingController controller;
  var preIcon;
  final name;
  Function onTTap;
  double hei;
  TextFieldWidget(
      {Key? key,
      this.name,
      required this.controller,
      required this.onTTap,
      required this.preIcon,
      required this.hei})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Container(
        height: hei,
        width: double.infinity,
        child: TextField(
          controller: controller,
          obscureText: false,
          onTap: () {
            onTTap();
          },
          decoration: InputDecoration(
            prefixIcon: preIcon == null ? null : Icon(preIcon),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MAINCOLOR, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2.0, color: Color(0xffD6D3D3)),
            ),
            hintText: name,
          ),
        ),
      ),
    );
  }
}
