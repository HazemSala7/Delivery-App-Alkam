import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:optimus_opost/Server/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Components/text_field_widget/text_field_widget.dart';

class DetectLocationDialog extends StatefulWidget {
  Function detectLocaion;
  final shipment_id;
  DetectLocationDialog({
    Key? key,
    required this.detectLocaion,
    required this.shipment_id,
  }) : super(key: key);

  @override
  State<DetectLocationDialog> createState() => _DetectLocationDialogState();
}

class _DetectLocationDialogState extends State<DetectLocationDialog> {
  @override
  TextEditingController searchController = TextEditingController();
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
                    Image.asset(
                      "assets/detect_location.png",
                      height: 80,
                      width: 80,
                    )
                  ],
                ),
                TitleInput(name: "تحديث الموقع"),
                Container(
                  width: double.infinity,
                  height: 50,
                  child: Text(
                      "لمساعدة السائق علي تحديد موقعك بدقة درجة تحديد موقعك بالضغط علي الزر “تحديد الموقع”"),
                ),
                Padding(
                    padding:
                        const EdgeInsets.only(right: 25, left: 25, top: 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: InkWell(
                            onTap: () async {
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
                              LocationData? currentLocation;
                              var location = new Location();
                              try {
                                currentLocation = await location.getLocation();
                              } on Exception {
                                currentLocation = null;
                              }
                              addLocation(
                                  context,
                                  currentLocation!.latitude,
                                  currentLocation.longitude,
                                  widget.shipment_id);
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                  color: MAINCOLOR,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text(
                                  "تحديد الموقع",
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

  Widget TitleInput({String name = ""}) {
    return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: MAINCOLOR),
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
