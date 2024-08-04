import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimus_opost/Components/button_widget/button_widget.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Components/text_field_widget/text_field_widget.dart';
import '../../Server/server.dart';
import '../shipments/shipments.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      passwordController.text = prefs.getString('password') ?? "";
      mobileController.text = prefs.getString('phone') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 100,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(150),
                child: Image.asset(
                  "assets/logo2.png",
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(
                height: 40,
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
        const SizedBox(
          height: 20,
        ),
        const SizedBox(
          width: 300,
          child: Center(
            child: Text(
              "قم بإدخال رقم الموبايل الخاص بك لعرض الشحنة, ستصلك رسالة تحتوي على رمز التحقق",
              textAlign: TextAlign.center,
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
                name: "رقم الهاتف",
              ),
              const SizedBox(
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
                      content: const Text(
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
            name: "تسجيل الدخول",
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
      int role_id = data["user"]['role_id'] ?? 1;
      if (role_id == 3) {
        await prefs.setString('phone', mobileController.text);
        await prefs.setString(
            'salesmanId', data["user"]['salesman_id'].toString());
        print(data["user"]['salesman_id'].toString());
        await prefs.setString('password', passwordController.text);
        await prefs.setString('active', data["driver"]['active']);
        await prefs.setString('driver_name', data["driver"]['name']);
        await prefs.setString('driver_serial', data["driver"]['serial_number']);
        await prefs.setBool('login', true);

        Fluttertoast.showToast(
          msg: 'تم تسجيل الدخول بنجاح',
        );

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Shipments(
                      status: data["driver"]['active'],
                    )));
      } else {
        Fluttertoast.showToast(msg: "غير مصرح لدخول التطبيق");
      }
    } else if (data['message'] == 'Invalid login details') {
      Navigator.of(context, rootNavigator: true).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text('الرجاء التأكد من البيانات المدخله'),
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
}
