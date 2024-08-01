import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:optimus_opost/Server/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Components/text_field_widget/text_field_widget.dart';

class AddNoteDialog extends StatefulWidget {
  final ship_id;
  AddNoteDialog({
    Key? key,
    required this.ship_id,
  }) : super(key: key);

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  @override
  TextEditingController noteController = TextEditingController();
  TextEditingController postponedController = TextEditingController();
  bool delay = false;
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        width: double.maxFinite,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Material(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "ملاحظه جديده",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: MAINCOLOR),
                    ),
                  ],
                ),
                TitleInput(name: "الملاحظه"),
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 10, top: 5),
                  child: TextFieldWidget(
                    onTTap: () {},
                    preIcon: null,
                    hei: 80,
                    controller: noteController,
                    name: "نص الملاحظه",
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 25, left: 25, top: 10),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    child: Row(
                      children: [
                        Checkbox(
                            value: delay,
                            onChanged: (_) {
                              setState(() {
                                delay = !delay;
                              });
                            }),
                        Text("تأجيل موعد التسليم")
                      ],
                    ),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Color(0xffD6D3D3))),
                  ),
                ),
                Visibility(
                    visible: delay,
                    child: TitleInput(name: "موعد التسليم الجديد")),
                Visibility(
                  visible: delay,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10, left: 10, top: 5),
                    child: TextFieldWidget(
                      onTTap: () {
                        setStart();
                      },
                      preIcon: Icons.date_range,
                      hei: 50,
                      controller: postponedController,
                      name: "موعد التسليم الجديد",
                    ),
                  ),
                ),
                Padding(
                    padding:
                        const EdgeInsets.only(right: 25, left: 25, top: 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: SizedBox(
                                        height: 100,
                                        width: 100,
                                        child: Center(
                                            child: CircularProgressIndicator(
                                          color: MAINCOLOR,
                                        ))),
                                  );
                                },
                              );
                              addNote(
                                  context,
                                  noteController.text,
                                  widget.ship_id,
                                  delay ? postponedController.text : "");
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                  color: MAINCOLOR,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  "ارسال",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Expanded(
                          flex: 1,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                    color: MAINCOLOR,
                                  ),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  "اغلاق",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: MAINCOLOR,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  setStart() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(
            2000), //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime(2101));

    if (pickedDate != null) {
      // print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      // print(
      //     formattedDate); //formatted date output using intl package =>  2021-03-16
      //you can implement different kind of Date Format here according to your requirement

      setState(() {
        postponedController.text =
            formattedDate; //set output date to TextField value.
      });
    } else {
      // print("Date is not selected");
    }
  }

  Widget TitleInput({String name = ""}) {
    return Padding(
        padding: const EdgeInsets.only(right: 25, left: 25, top: 10),
        child: Row(
          children: [
            Text(
              name,
              style: TextStyle(fontSize: 18),
            )
          ],
        ));
  }

  bool _obscureText = true;
  toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
}
