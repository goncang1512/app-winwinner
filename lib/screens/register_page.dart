import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/states/http_api.dart';
import '../widgets/logo.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<RegisterPage> {
  final _controller = TextEditingController();
  final _passwordText = TextEditingController();
  final _usernameteText = TextEditingController();
  final api = ApiService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fungsi untuk memproses login
  void _login() async {
    final email = _controller.text.trim();
    final password = _passwordText.text.trim();
    final username = _usernameteText.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama terlebih dahulu!')),
      );
      return;
    }

    await api.post("/auth/signup", {
      "username": username,
      "email": email,
      "password": password,
    });

    // Navigasi ke HomePage
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFB300),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Tentukan breakpoint Anda. 600 adalah standar umum.
          if (constraints.maxWidth > 600) {
            // --- TAMPILAN LEBAR (TABLET / WEB) ---
            return _buildWideLayout(constraints);
          } else {
            // --- TAMPILAN SEMPIT (HP - POTRET ATAU LANDSCAPE) ---
            return _buildNarrowLayout(constraints);
          }
        },
      ),
    );
  }

  //build layout untuk layar hp
  Widget _buildNarrowLayout(BoxConstraints constraints) {
    // Ukuran dinamis berdasarkan layout
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
                Logo(size: logoSize * 0.8), // Logo
                SizedBox(height: verticalSpacing),
                _buildLoginForm(inputFontSize, buttonFontSize, screenHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //build layout untuk layar lebar dan rotate
  Widget _buildWideLayout(BoxConstraints constraints) {
    // Ukuran dinamis berdasarkan layout
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

  //widget untuk form
  Widget _buildLoginForm(
    double inputFontSize,
    double buttonFontSize,
    double screenHeight,
  ) {
    return Column(
      children: [
        // Input nama
        TextField(
          controller: _usernameteText,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: inputFontSize),
          decoration: InputDecoration(
            hintText: 'Masukkan username...',
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

        // Tombol masuk
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
              'Sudah punya akun? ',
              style: TextStyle(
                color: Colors.white,
                fontSize: inputFontSize * 0.9,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.go('/login'); // route ke halaman register
              },
              child: Text(
                'Login di sini',
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
