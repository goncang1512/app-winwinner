import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/states/auth_state.dart';
import '../widgets/logo.dart';
import '../widgets/back_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFB300),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        elevation: 0,
        leading: BackButtonWidget(
          onPressed: () {
            context.go('/login');
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // --- TAMPILAN LEBAR (TABLET) ---
            return _buildWideLayout(context, constraints);
          } else {
            // --- TAMPILAN SEMPIT (HP) ---
            return _buildNarrowLayout(context, constraints);
          }
        },
      ),
    );
  }

  //build layout untuk screen HP
  Widget _buildNarrowLayout(BuildContext context, BoxConstraints constraints) {
    // Ukuran dinamis
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final logoSize = screenHeight * 0.35;
    final welcomeFontSize = screenWidth * 0.06;
    final buttonFontSize = screenWidth * 0.05;
    final verticalSpacingLarge = screenHeight * 0.06;
    final verticalSpacingSmall = screenHeight * 0.025;
    final horizontalPadding = screenWidth * 0.1;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
            ).copyWith(bottom: verticalSpacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Logo(size: logoSize),
                SizedBox(height: verticalSpacingSmall),
                _buildMenu(
                  context,
                  welcomeFontSize,
                  buttonFontSize,
                  verticalSpacingLarge,
                  verticalSpacingSmall,
                  screenHeight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //build layout untuk layar lebar dan rotate
  Widget _buildWideLayout(BuildContext context, BoxConstraints constraints) {
    // Ukuran dinamis
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final logoSize = screenWidth * 0.25;
    final welcomeFontSize = screenWidth * 0.03;
    final buttonFontSize = screenWidth * 0.025;
    final verticalSpacingLarge = screenHeight * 0.06;
    final verticalSpacingSmall = screenHeight * 0.025;
    final horizontalPadding = screenWidth * 0.1;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Center(child: Logo(size: logoSize)),
            ),
            SizedBox(width: horizontalPadding / 2),
            Expanded(
              flex: 1,
              child: _buildMenu(
                context,
                welcomeFontSize,
                buttonFontSize,
                verticalSpacingLarge,
                verticalSpacingSmall,
                screenHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //wdiget Menu
  Widget _buildMenu(
    BuildContext context,
    double welcomeFontSize,
    double buttonFontSize,
    double verticalSpacingLarge,
    double verticalSpacingSmall,
    double screenHeight,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Teks selamat datang
        FutureBuilder(
          future: AuthService.getSession(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Text(
                'Selamat Datang!!\nGuest',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: welcomeFontSize,
                  fontWeight: FontWeight.bold,
                ),
              );
            }

            final user = snapshot.data?['result'] as Map<String, dynamic>;

            // 🔥 SESUAIKAN DENGAN RESPONSE BACKEND
            final username = user['username'] ?? 'User';

            return Text(
              'Selamat Datang!!\n$username',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: welcomeFontSize,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        SizedBox(height: verticalSpacingLarge),

        // Tombol Main
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              context.go('/game');
            },
            child: Text(
              'Main',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: verticalSpacingSmall),

        // Tombol Panduan
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              context.go('/panduan');
            },
            child: Text(
              'Panduan',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        SizedBox(height: verticalSpacingSmall),

        // Tombol Panduan
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () async {
              context.go("/leaderboard");
            },
            child: Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        SizedBox(height: verticalSpacingSmall),

        // Tombol Panduan
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () async {
              await AuthService.logout();
              context.go("/login");
            },
            child: Text(
              'Logout',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
