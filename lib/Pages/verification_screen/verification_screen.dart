// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:optimus_opost/Components/button_widget/button_widget.dart';
// import 'package:optimus_opost/Pages/shipments/shipments.dart';
// import 'package:optimus_opost/Server/functions.dart';
// import 'package:sms_otp_auto_verify/sms_otp_auto_verify.dart';

// import '../../Constants/constants.dart';

// class VerificationScreen extends StatefulWidget {
//   final verification, mobile_intro, mobile;
//   const VerificationScreen(
//       {super.key, this.verification, this.mobile_intro, this.mobile});

//   @override
//   State<VerificationScreen> createState() => _VerificationScreenState();
// }

// class _VerificationScreenState extends State<VerificationScreen> {
//   @override
//   int _otpCodeLength = 4;
//   TextEditingController textEditingController = TextEditingController();
//   String _otpCode = "";

//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Center(
//           child: Column(
//             children: [
//               SizedBox(
//                 height: 50,
//               ),
//               Text(
//                 "ادخال رمز التحقق",
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 28,
//                     color: MAINCOLOR),
//               ),
//               SizedBox(
//                 height: 20,
//               ),
//               Container(
//                 width: 300,
//                 child: Center(
//                   child: Text(
//                     "ستصلك رسالة تحتوي على رمز التحقق من رقم الجوال الخاص بك.",
//                     style: TextStyle(fontSize: 15, color: Color(0xff0A0A0A)),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(top: 20),
//                 child: Directionality(
//                   textDirection: TextDirection.ltr,
//                   child: TextFieldPin(
//                       textController: textEditingController,
//                       autoFocus: true,
//                       codeLength: _otpCodeLength,
//                       alignment: MainAxisAlignment.center,
//                       defaultBoxSize: 55.0,
//                       margin: 10,
//                       selectedBoxSize: 55.0,
//                       textStyle:
//                           TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                       // defaultDecoration: _pinPutDecoration.copyWith(
//                       //     border: Border.all(
//                       //         color:
//                       //             Theme.of(context).primaryColor.withOpacity(0.6))),
//                       selectedDecoration: BoxDecoration(
//                         border: Border.all(color: MAINCOLOR, width: 2),
//                         borderRadius: BorderRadius.circular(15.0),
//                       ),
//                       defaultDecoration: BoxDecoration(
//                         border: Border.all(color: Color(0xffD9D9D9), width: 2),
//                         borderRadius: BorderRadius.circular(15.0),
//                       ),
//                       onChange: (code) {
//                         setState(() {});
//                       }),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(top: 40, left: 25, right: 25),
//                 child: ButtonWidget(
//                     name: "تحقق",
//                     OnClick: () async {
//                       showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return AlertDialog(
//                             content: SizedBox(
//                                 height: 100,
//                                 width: 100,
//                                 child: Center(
//                                     child: CircularProgressIndicator(
//                                   color: MAINCOLOR,
//                                 ))),
//                           );
//                         },
//                       );
//                       await checkVerificationCode(
//                           context,
//                           textEditingController.text,
//                           widget.mobile,
//                           widget.mobile_intro);
//                     }),
//               ),
//               // Padding(
//               //   padding: const EdgeInsets.only(top: 40),
//               //   child: Text(
//               //     "اعاده الارسال (01:41)",
//               //     style: TextStyle(fontSize: 16, color: Color(0xffBEBBD7)),
//               //   ),
//               // ),
//               Padding(
//                 padding: const EdgeInsets.only(top: 20),
//                 child: InkWell(
//                   onTap: () {
//                     Navigator.pop(context);
//                   },
//                   child: Text(
//                     "تغيير رقم الجوال",
//                     style: TextStyle(fontSize: 18, color: MAINCOLOR),
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
