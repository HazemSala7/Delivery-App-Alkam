import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:optimus_opost/Pages/shipments_from_to/shipments_from_to.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optimus_opost/l10n/app_localizations.dart';
import '../../Components/text_field_widget/text_field_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  TextEditingController FormController = TextEditingController();
  TextEditingController ToController = TextEditingController();

  Widget build(BuildContext context) {
    String dropdownValue = AppLocalizations.of(context)!.all;
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(),
                    Text(
                      AppLocalizations.of(context)!.filter,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: MAINCOLOR),
                    ),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            FormController.text = "";
                            ToController.text = "";
                          });
                        },
                        icon: Icon(
                          Icons.refresh,
                          size: 30,
                          color: MAINCOLOR,
                        ))
                  ],
                ),
                TitleInput(name: AppLocalizations.of(context)!.from_date),
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 10, top: 5),
                  child: TextFieldWidget(
                    onTTap: () {
                      setStart();
                    },
                    preIcon: Icons.date_range,
                    hei: 50,
                    controller: FormController,
                    name: AppLocalizations.of(context)!.from_date,
                  ),
                ),
                TitleInput(name: AppLocalizations.of(context)!.to_date),
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 10, top: 5),
                  child: TextFieldWidget(
                    onTTap: () {
                      setEnd();
                    },
                    preIcon: Icons.date_range,
                    hei: 50,
                    controller: ToController,
                    name: AppLocalizations.of(context)!.to_date,
                  ),
                ),
                TitleInput(
                    name: AppLocalizations.of(context)!.shipments_status),
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 2.0, color: const Color(0xffD6D3D3)),
                        borderRadius: BorderRadius.circular(4)),
                    child: Center(
                      child: DropdownButtonFormField<String>(
                        alignment: AlignmentDirectional.center,
                        isExpanded: true,
                        decoration: const InputDecoration(),
                        value: dropdownValue,
                        items: <String>[
                          AppLocalizations.of(context)!.all,
                          AppLocalizations.of(context)!.under_processing,
                          AppLocalizations.of(context)!.delivered,
                          AppLocalizations.of(context)!.returned,
                          AppLocalizations.of(context)!.cancelled,
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  value,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        // Step 5.
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownValue = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 25, left: 25, top: 35),
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    height: 50,
                    minWidth: double.infinity,
                    color: MAINCOLOR,
                    textColor: Colors.white,
                    child: Text(
                      AppLocalizations.of(context)!.search,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ShipmentsFromTo(
                                    from: FormController.text,
                                    to: ToController.text,
                                    status: dropdownValue,
                                  )));
                    },
                  ),
                ),
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
        FormController.text =
            formattedDate; //set output date to TextField value.
      });
    } else {
      // print("Date is not selected");
    }
  }

  setEnd() async {
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
        ToController.text = formattedDate; //set output date to TextField value.
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
}
