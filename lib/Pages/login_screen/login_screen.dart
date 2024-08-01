import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimus_opost/Components/button_widget/button_widget.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:optimus_opost/Pages/verification_screen/verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Components/text_field_widget/text_field_widget.dart';
import '../../Server/functions.dart';
import '../../Server/server.dart';
import '../shipments/shipments.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  bool mobile = true;
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 50,
              ),
              Image.asset(
                "assets/truck_login.png",
                height: 70,
                width: 70,
              ),
              SizedBox(
                height: 180,
              ),
              MobileWidget()
            ],
          ),
        ),
      ),
    );
  }

  Widget MobileWidget() {
    return Column(
      children: [
        Text(
          "تأكيد رقم الموبايل",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: MAINCOLOR),
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          width: 300,
          child: Center(
            child: Text(
              "قم بإدخال رقم الموبايل الخاص بك لعرض الشحنة, ستصلك رسالة تحتوي على رمز التحقق",
              style: TextStyle(fontSize: 15, color: Color(0xff0A0A0A)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 25, left: 25, top: 60),
          child: Column(
            children: [
              TextFieldWidget(
                controller: mobileController,
                hei: 50,
                onTTap: () {},
                preIcon: Icons.phone,
                name: "Ex : 0599 567 124",
              ),
              SizedBox(
                height: 10,
              ),
              TextFieldWidget(
                controller: passwordController,
                hei: 50,
                onTTap: () {},
                preIcon: Icons.password,
                name: "كلمة المرور",
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 25, left: 25, top: 20),
          child: ButtonWidget(
            OnClick: () async {
              if (mobileController.text == "" ||
                  passwordController.text == "") {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text(
                        "الرجاء ادخل رقم الهاتف و كلمة المرور",
                      ),
                      actions: <Widget>[
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 35,
                            width: 150,
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: MAINCOLOR,
                                ),
                                borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Text(
                                "حسنا",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: MAINCOLOR,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              } else {
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
                await loginFunction();
              }
            },
            name: "ارسل الرمز",
          ),
        ),
      ],
    );
  }

  loginFunction() async {
    var url = URL_LOGIN;
    var response = await http.post(Uri.parse(url), body: {
      "phone": mobileController.text,
      "password": passwordController.text,
    });
    var data = jsonDecode(response.body.toString());
    if (data['status'] == 'true') {
      Navigator.of(context, rootNavigator: true).pop();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int role_id = data["user"]['role_id'] ?? "1";
      await prefs.setString('role_id', role_id.toString());
      await prefs.setBool('login', true);
      Fluttertoast.showToast(
        msg: 'تم تسجيل الدخول بنجاح',
      );
      role_id == 2
          ? Navigator.push(
              context, MaterialPageRoute(builder: (context) => Shipments()))
          : Navigator.push(
              context, MaterialPageRoute(builder: (context) => Shipments()));
    } else if (data['message'] == 'Invalid login details') {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('الرجاء التأكد من البيانات المدخله'),
            actions: <Widget>[
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "حسنا",
                  style: TextStyle(color: MAINCOLOR),
                ),
              ),
            ],
          );
        },
      );
    } else {
      print('sdfsd');
    }
  }

  List<String> list = <String>[
    '972+',
    '970+',
  ];
  String dropdownValue = "972+";
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
}
