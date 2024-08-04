import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optimus_opost/Pages/login_screen/login_screen.dart';
import 'package:optimus_opost/Server/server.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Pages/shipments/shipments.dart';

Map<String, String> Body = {
  "client_id": "2",
  "client_secret": "3OH4gQLbGNJMVvj8lFij0GBO4iUnwNqIFip6hX8l",
  "mobile_intro": "00972",
  "mobile": "0595324689",
  // "tracking_number": "184864684",
  // "signature": "jbEhD22AQeUnXXMhr+1dSUXQqTk27Vw+1CBq6lsESLU=",
  "signed_field_names":
      "client_id,client_secret,mobile_intro,mobile,datetime,signed_field_names",
  // "datetime": "2023-05-09T14:30:15.113Z"
};
var headers = {
  'ContentType': 'application/json',
  "Device-Id": "postman-device-id",
  "Device-Token": "postman-random-token",
  "Device-Os": "Windows",
  "Authorization":
      "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIyIiwianRpIjoiZDQ3NWUwMDJkNjBiNGYxYjEzOTg0ZWJhZjJhZTVlYzdmMjk2OTdlYzc1NTY0ZDM5OTJiYzc2MzU1MWQ4MGEzOWMyMjVkMzIxOTNjZjQ2Y2UiLCJpYXQiOjE2ODE1NjA3MDguMzMyNDk1LCJuYmYiOjE2ODE1NjA3MDguMzMyNDk4LCJleHAiOjE3MTMxODMxMDguMzA3Mzc3LCJzdWIiOiI1NTgiLCJzY29wZXMiOltdfQ.U78WSUzrajlBtv1ddKsngqjD8JaKcHdGrKHyNANyI9YVt4Q1Cw4AckE5U6xdZbDcG7M6cPIJXiyJXgFqfuMhzELPWNwoXGeMxylEq64T5ww7k5bKJFs5BB3Kp4b4OBx8-dcsxZ5gxegMAn8iI8k-GLQlmZjaG29RxJXqTnslxvSKK2Ur0AiRl7QNd464EDl7vwRyFKkPwgbpkOkTmCKzjLK7eVHpsoQMie3e37wDvFeSozadljII960Q_gLJ_yRRXtGeL-Ie3uI5qbrqkcH4D7hhaYeOlbpiiRdx4byW3EPcNEhGnOjTNtWN3MnCPHbRj-_dGz0-70TsMq-sXcT4C7eQYwro42WlZSfDvtI2J5tM9PUs7aOL3DO4uoM52bpSzUuj3nEDIagaOTOCeLV5zRdFSXSNHz_VNMfqWMZmLX0Ii-ILX4_zWrW4iJ5KAxXj04-RuyMP4uOlmZYAVAn7O7BCm90QEpEG6mom4j8ARhF26id3fu8KydWVGeOa3aGZnP80j406UlplZKODeHKlnRtGc8g9695OTifq_VHQWHBX7n89RVm0l2p3q3NDd03ZdkURxaqBf6mJgrqXhyGoBPCM9Ul8d4z7IhCb1bVSHIoEbgsitDOkYpwvTL7ezNTcNWPLSDKa6dLE6Xuao_kTdL0AwbZqKbctkY1t9P6Ates",
  "Accept": "application/json"
};

getRequest(API_URL) async {
  var response = await http.get(Uri.parse(API_URL), headers: headers);
  var res = jsonDecode(response.body);
  return res;
}

getShipments(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');
  Map<String, String> qParams = {
    'grant_type': 'password',
    'client_id': '2',
    'client_secret': '3OH4gQLbGNJMVvj8lFij0GBO4iUnwNqIFip6hX8l',
    'username': 'test11@gmail.com',
    'password': 'test11@gmail.com',
    'scope': '',
  };
  Uri uri = Uri.parse(URL_SHIPMENTS);
  final finalUri = uri.replace(queryParameters: qParams);
  var response = await http.get(
    finalUri,
    headers: {
      'ContentType': 'application/json',
      "Device-Id": "postman-device-id",
      "Device-Token": "postman-random-token",
      "Device-Os": "Windows",
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    },
  );
  if (response.statusCode == 401) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  } else {
    var res = jsonDecode(response.body);
    return res;
  }
}

getShipmentStatus(shipment) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');
  var response = await http.get(
    Uri.parse("$URL_SHIPMENTS_STATUS?shipment=$shipment"),
    headers: {
      'ContentType': 'application/json',
      "Device-Id": "postman-device-id",
      "Device-Token": "postman-random-token",
      "Device-Os": "Windows",
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    },
  );
  var res = jsonDecode(response.body);
  return res;
}

filterShipmentsStatus(status) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');
  Map<String, String> under = {
    "status[0]": "draft",
    "status[1]": "picked_up",
    "status[2]": "submitted",
    "status[3]": "pending",
    "status[4]": "pending_pickup",
  };
  Map<String, String> deli = {
    "status[0]": "cod_picked_up",
    "status[1]": "delivered",
    "status[2]": "in_accounting",
    "status[3]": "closed",
  };
  Map<String, String> ret = {
    "status[0]": "returned",
  };
  Map<String, String> canceled = {
    "status[0]": "canceled",
  };
  Uri uri = Uri.parse(URL_SHIPMENTS);
  final finalUri = uri.replace(
      queryParameters: status == "under"
          ? under
          : status == "deliverd"
              ? deli
              : status == "returned"
                  ? ret
                  : status == "canceleed"
                      ? canceled
                      : null);
  var response = await http.get(
    finalUri,
    headers: {
      'ContentType': 'application/json',
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    },
  );

  var res = jsonDecode(response.body);
  return res;
}

filterShipmentsFromTo(status, from, to) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');
  Map<String, String> under = {
    "status[0]": "draft",
    "status[1]": "picked_up",
    "status[2]": "submitted",
    "status[3]": "pending",
    "status[4]": "pending_pickup",
  };
  Map<String, String> deli = {
    "status[0]": "cod_picked_up",
    "status[1]": "delivered",
    "status[2]": "in_accounting",
    "status[3]": "closed",
  };
  Map<String, String> ret = {
    "status[0]": "returned",
  };
  Map<String, String> canceled = {
    "status[0]": "canceled",
  };
  Uri uri =
      Uri.parse("$URL_SHIPMENTS?&created_at[from]=$from&created_at[to]=$to");
  final finalUri = uri.replace(
      queryParameters: status == "under"
          ? under
          : status == "deliverd"
              ? deli
              : status == "returned"
                  ? ret
                  : status == "canceleed"
                      ? canceled
                      : null);
  var response = await http.get(
    finalUri,
    headers: {
      'ContentType': 'application/json',
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    },
  );
  var res = jsonDecode(response.body);
  return res;
}

filterShipmentsTrackingNumber(track) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');
  var response = await http.get(
    Uri.parse("$URL_SHIPMENTS?tracking_number[0]=$track"),
    headers: {
      'ContentType': 'application/json',
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    },
  );
  var res = jsonDecode(response.body);
  return res;
}

getSpeceficShipment(shipment) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');
  var response = await http.get(
    Uri.parse("$URL_SHIPMENTS/$shipment"),
    headers: {
      'ContentType': 'application/json',
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    },
  );
  var res = jsonDecode(response.body);
  return res;
}

getNotifications() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');
  Uri uri = Uri.parse(URL_NOTIFICATIONS);
  var response = await http.get(
    uri,
    headers: {
      'ContentType': 'application/json',
      "Device-Id": "postman-device-id",
      "Device-Token": "postman-random-token",
      "Device-Os": "Windows",
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    },
  );
  var res = jsonDecode(response.body);
  return res;
}

getNotificationsCount() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');
  Uri uri = Uri.parse(URL_NOTIFICATIONS_COUNT);
  var response = await http.get(
    uri,
    headers: {
      'ContentType': 'application/json',
      "Device-Id": "postman-device-id",
      "Device-Token": "postman-random-token",
      "Device-Os": "Windows",
      "Authorization": "Bearer $token",
      "Accept": "application/json"
    },
  );
  var res = jsonDecode(response.body);
  return res;
}

conigneeMobile(BuildContext context, mob_intro, mobile, trackingNumber) async {
  if (trackingNumber.toString() != "") {
    Body["tracking_number"] = trackingNumber.toString();
  }
  makeSignature(mob_intro, mobile);
  var response =
      await http.post(Uri.parse(URL_MOBILE), body: Body, headers: headers);
  var data = json.decode(response.body);
  if (data['status'] == true) {
    Navigator.of(context, rootNavigator: true).pop();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('login', true);
    return "true";
  } else {
    Navigator.of(context, rootNavigator: true).pop();
    return "false";
  }
}

// checkVerificationCode(BuildContext context, code, mobile, mobile_intro) async {
//   var response = await http.post(Uri.parse("https://opost.ps/oauth/token"),
//       body: {
//         "client_id": "2",
//         "client_secret": "3OH4gQLbGNJMVvj8lFij0GBO4iUnwNqIFip6hX8l",
//         "mobile": mobile.toString(),
//         "mobile_intro": mobile_intro.toString(),
//         "grant_type": "mobile_otp",
//         "otp_code": code.toString(),
//         "scope": ""
//       },
//       headers: headers);
//   var data = json.decode(response.body);
//   if (data['token_type'] == "Bearer") {
//     Navigator.of(context, rootNavigator: true).pop();
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String token = data['access_token'] ?? "";
//     await prefs.setString('access_token', token);
//     Fluttertoast.showToast(
//       msg: "تم التحقق من الكود بنجاح",
//     );
//     Navigator.push(
//         context, MaterialPageRoute(builder: (context) => Shipments()));
//   } else {
//     Navigator.of(context, rootNavigator: true).pop();
//     Fluttertoast.showToast(msg: "الكود المدخل خطأ , الرجاء المحاوله مره أخرى");
//   }
// }

addNote(BuildContext context, note, shipment_id, postponedData) async {
  var response = await http.post(Uri.parse(URL_ADD_NOTE),
      body: {
        "notes": note.toString(),
        "selected_ids[0]": shipment_id,
        "postpone_delivery": postponedData.toString()
      },
      headers: headers);
  var data = json.decode(response.body);
  if (response.statusCode == 200) {
    Navigator.of(context, rootNavigator: true).pop();
    Fluttertoast.showToast(msg: "تم اضافه الملاحظه بنجاح");
    return "true";
  } else {
    Navigator.of(context, rootNavigator: true).pop();
    Fluttertoast.showToast(
        msg: "فشلت عمليه اضافه الملاحظه , الرجاء المحاوله فيما بعد");
    return "false";
  }
}

addLocation(BuildContext context, latitude, lonitude, ship_id) async {
  var response = await http.post(Uri.parse(URL_ADD_LOCATION),
      body: {
        "latitude": latitude.toString(),
        "longitude": lonitude.toString(),
        "shipment_id": ship_id.toString()
      },
      headers: headers);
  var data = json.decode(response.body);
  if (response.statusCode == 200) {
    Navigator.of(context, rootNavigator: true).pop();
    Fluttertoast.showToast(msg: "تم تعديل بيانات الموقع بنجاح");
    Navigator.pop(context);
    Navigator.pop(context);
    return "true";
  } else {
    Navigator.of(context, rootNavigator: true).pop();
    Fluttertoast.showToast(
        msg: "فشلت عمليه اضافه الموقع , الرجاء المحاوله فيما بعد");
    return "false";
  }
}

makeSignature(mobile_intro, mobile) {
  var f = DateFormat('yyyyMMddH');
  var date = f.format(DateTime.now().toUtc());

  String DateTime1 = DateTime.now().toUtc().toString();

  var secretkey = md5
      .convert(utf8.encode(
          'opost-app' + '3OH4gQLbGNJMVvj8lFij0GBO4iUnwNqIFip6hX8l' + date))
      .toString();

  var dataToSign =
      "client_id=2,client_secret=3OH4gQLbGNJMVvj8lFij0GBO4iUnwNqIFip6hX8l,mobile_intro=$mobile_intro,mobile=$mobile,datetime=$DateTime1,signed_field_names=client_id,client_secret,mobile_intro,mobile,datetime,signed_field_names";
  // var signature =
  //     base64_encode(hash_hmac('sha256', dataToSign, secretkey, true));

  var key = utf8.encode(secretkey);
  var bytes = utf8.encode(dataToSign);

  var hmacSha256 = new Hmac(sha256, key);
  var digest = hmacSha256.convert(bytes);

  String base64Mac = base64.encode(digest.bytes);
  Body["signature"] = base64Mac.toString();
  Body["datetime"] = DateTime1;
  Body["mobile"] = mobile;
  Body["mobile_intro"] = mobile_intro;
}
