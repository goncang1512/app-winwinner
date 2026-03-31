import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/states/auth_state.dart';
import 'package:uts/states/http_api.dart';
import '../widgets/logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();
  final _passwordText = TextEditingController();
  final api = ApiService();

  @override
  void initState() {
    super.initState();
    // ✅ Cek token saat halaman pertama kali dibuka
    _checkToken();
  }

  // Jika sudah ada token, langsung ke /home
  Future<void> _checkToken() async {
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      if (mounted) context.go('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _passwordText.dispose();
    super.dispose();
  }

  // Fungsi untuk memproses login
  void _login() async {
    final email = _controller.text.trim();
    final password = _passwordText.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email terlebih dahulu!')),
      );
      return;
    }

    try {
      final data = await api.post("/auth/login", {
        "email": email,
        "password": password,
      });

      await AuthService.saveToken(data['result']['token']);

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login gagal: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFB300),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildWideLayout(constraints);
          } else {
            return _buildNarrowLayout(constraints);
          }
        },
      ),
    );
  }

  Widget _buildNarrowLayout(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final logoSize = screenHeight * 0.35;
    final inputFontSize = screenWidth * 0.045;
    final buttonFontSize = screenWidth * 0.045;
    final verticalSpacing = screenHeight * 0.03;
    final horizontalPadding = screenWidth * 0.1;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
          ).copyWith(top: screenHeight * 0.1),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Logo(size: logoSize * 0.8),
                SizedBox(height: verticalSpacing),
                _buildLoginForm(inputFontSize, buttonFontSize, screenHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final logoSize = screenWidth * 0.25;
    final inputFontSize = screenWidth * 0.02;
    final buttonFontSize = screenWidth * 0.02;
    final horizontalPadding = screenWidth * 0.1;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Center(child: Logo(size: logoSize)),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLoginForm(inputFontSize, buttonFontSize, screenHeight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    double inputFontSize,
    double buttonFontSize,
    double screenHeight,
  ) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: inputFontSize),
          decoration: InputDecoration(
            hintText: 'Masukkan email...',
            hintStyle: TextStyle(
              color: Colors.white70,
              fontSize: inputFontSize * 0.9,
            ),
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        TextField(
          controller: _passwordText,
          obscureText: true,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: inputFontSize),
          decoration: InputDecoration(
            hintText: 'Masukkan password...',
            hintStyle: TextStyle(
              color: Colors.white70,
              fontSize: inputFontSize * 0.9,
            ),
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _login,
            child: Text(
              'Masuk',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Belum punya akun? ',
              style: TextStyle(
                color: Colors.white,
                fontSize: inputFontSize * 0.9,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: Text(
                'Daftar di sini',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: inputFontSize * 0.9,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
