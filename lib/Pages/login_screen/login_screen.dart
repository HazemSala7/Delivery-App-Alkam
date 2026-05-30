import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:optimus_opost/Constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Server/server.dart';
import '../shipments/shipments.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String myToken = "";
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    loadData();
    getToken();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      passwordController.text = prefs.getString('password') ?? "";
      mobileController.text = prefs.getString('phone') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MAINCOLOR,
                MAINCOLOR.withOpacity(0.85),
                const Color(0xFF6E1418),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(),
                        _buildFormCard(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Column(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(150),
              child: Image.asset(
                "assets/logo2.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "مرحباً بعودتك",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "سجل الدخول للمتابعة إلى حسابك",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              "تسجيل الدخول",
              style: TextStyle(
                color: MAINCOLOR,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "قم بإدخال رقم هاتفك وكلمة المرور للمتابعة",
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            _buildField(
              controller: mobileController,
              label: "رقم الهاتف",
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "الرجاء إدخال رقم الهاتف"
                  : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: passwordController,
              label: "كلمة المرور",
              icon: Icons.lock_rounded,
              obscure: _obscurePassword,
              suffix: IconButton(
                splashRadius: 20,
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: const Color(0xFF95A5A6),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? "الرجاء إدخال كلمة المرور"
                  : null,
            ),
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 14),
            Center(
              child: Text(
                "© ${DateTime.now().year}",
                style:
                    const TextStyle(color: Color(0xFFBDC3C7), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF2C3E50),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7F8C8D)),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MAINCOLOR.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: MAINCOLOR, size: 20),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E6E6), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: MAINCOLOR, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC0392B), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : _onLoginPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: MAINCOLOR,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: MAINCOLOR.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "تسجيل الدخول",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await loginFunction();
    } catch (e) {
      _showMessageDialog(
        title: "خطأ غير متوقع",
        message:
            "حدث خطأ أثناء تسجيل الدخول. الرجاء المحاولة مرة أخرى.\n($e)",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessageDialog({
    required String title,
    required String message,
    bool isError = true,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isError ? Colors.red : Colors.green)
                        .withOpacity(0.1),
                  ),
                  child: Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isError
                        ? const Color(0xFFC0392B)
                        : const Color(0xFF27AE60),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MAINCOLOR,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "حسناً",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getToken() async {
    try {
      myToken = (await FirebaseMessaging.instance.getToken()) ?? "";
      print("FCM Token: $myToken");
    } catch (e) {
      print("Error getting token: $e");
    }
  }

  Future<void> sendTokenToServer(String token, String barrierToken) async {
    String apiUrl = URL_UPDATE_TOKEN;
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $barrierToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"fcm_token": token}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Token sent successfully!");
      } else {
        print("Failed to send token. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error sending token: $e");
    }
  }

  Future<void> loginFunction() async {
    var url = URL_LOGIN;
    http.Response response;
    try {
      response = await http.post(Uri.parse(url), body: {
        "phone": mobileController.text.trim(),
        "password": passwordController.text,
      });
    } catch (_) {
      _showMessageDialog(
        title: "خطأ في الاتصال",
        message:
            "تعذر الاتصال بالخادم. الرجاء التحقق من اتصالك بالإنترنت.",
        isError: true,
      );
      return;
    }

    dynamic data;
    try {
      data = jsonDecode(response.body.toString());
    } catch (_) {
      _showMessageDialog(
        title: "خطأ في الخادم",
        message: "حدث خطأ غير متوقع. الرجاء المحاولة لاحقاً.",
        isError: true,
      );
      return;
    }

    if (data['status'] == 'true') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String role_id = data["user"]?['role_id']?.toString() ?? "1";
      if (role_id == "3") {
        final user = data["user"] ?? {};
        final active = (user['active'] ?? '').toString();
        // The orders API keys orders by the driver's salesman/serial number
        // (e.g. "8608"), NOT the users-table primary key. Pick the right
        // field with safe fallbacks.
        final String salesmanIdValue = [
          user['salesman_id'],
          user['serial_number'],
          user['serial'],
          user['driver_id'],
          user['id'],
        ].firstWhere(
          (v) => v != null && v.toString().trim().isNotEmpty,
          orElse: () => '',
        ).toString();
        await prefs.setString('phone', mobileController.text);
        await prefs.setString('salesmanId', salesmanIdValue);
        await prefs.setString('password', passwordController.text);
        await prefs.setString('active', active);
        await prefs.setString(
            'driver_name', (user['name'] ?? '').toString());
        await prefs.setString(
            'driver_serial', (user['serial_number'] ?? '').toString());
        await prefs.setBool('login', true);

        await sendTokenToServer(
            myToken, (data["access_token"] ?? '').toString());

        Fluttertoast.showToast(msg: 'تم تسجيل الدخول بنجاح');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Shipments(status: active),
          ),
        );
      } else {
        _showMessageDialog(
          title: "غير مصرح",
          message: "هذا الحساب غير مصرح له بالدخول إلى التطبيق.",
          isError: true,
        );
      }
    } else if (data['message'] == 'Invalid login details') {
      _showMessageDialog(
        title: "بيانات غير صحيحة",
        message:
            "الرجاء التأكد من رقم الهاتف وكلمة المرور والمحاولة مجدداً.",
        isError: true,
      );
    } else {
      _showMessageDialog(
        title: "تعذر تسجيل الدخول",
        message: (data['message']?.toString().isNotEmpty == true)
            ? data['message'].toString()
            : "حدث خطأ أثناء تسجيل الدخول. حاول مرة أخرى.",
        isError: true,
      );
    }
  }
}
