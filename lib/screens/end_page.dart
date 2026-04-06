import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/logo.dart';
import '../widgets/back_button.dart';

class EndPage extends StatefulWidget {
  final String playerName;
  final int totalMoney;

  const EndPage({
    super.key,
    required this.playerName,
    required this.totalMoney,
  });

  @override
  State<EndPage> createState() => _EndPageState();
}

class _EndPageState extends State<EndPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playCorrect(); // ✅ Langsung play saat halaman dibuka
  }

  Future<void> _playCorrect() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.setVolume(0.9);
      await _audioPlayer.play(AssetSource('sound/jawaban-benar.mpeg'));
    } catch (e) {
      debugPrint('Correct sound error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // ✅ Bersihkan saat halaman ditutup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFont = screenWidth * 0.040;

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
        centerTitle: true,
        title: Text(
          'Permainan Selesai',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleFont,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildWideLayout(context, constraints);
          } else {
            return _buildNarrowLayout(context, constraints);
          }
        },
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final logoSize = screenHeight * 0.25;
    final textFont = screenWidth * 0.05;
    final buttonFont = screenWidth * 0.05;
    final paddingHorizontal = screenWidth * 0.1;
    final spacingSmall = screenHeight * 0.02;
    final spacingLarge = screenHeight * 0.05;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal,
        ).copyWith(top: spacingSmall, bottom: spacingLarge),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Logo(size: logoSize),
              SizedBox(height: spacingSmall),
              _buildScoreboard(
                context,
                textFont,
                buttonFont,
                screenHeight,
                screenWidth,
                spacingSmall,
                spacingLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final logoSize = screenWidth * 0.20;
    final textFont = screenWidth * 0.025;
    final buttonFont = screenWidth * 0.025;
    final paddingHorizontal = screenWidth * 0.1;
    final spacingSmall = screenHeight * 0.02;
    final spacingLarge = screenHeight * 0.05;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Center(child: Logo(size: logoSize)),
          ),
          SizedBox(width: paddingHorizontal / 2),
          Expanded(
            flex: 1,
            child: _buildScoreboard(
              context,
              textFont,
              buttonFont,
              screenHeight,
              screenWidth,
              spacingSmall,
              spacingLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard(
    BuildContext context,
    double textFont,
    double buttonFont,
    double screenHeight,
    double screenWidth,
    double spacingSmall,
    double spacingLarge,
  ) {
    final formatter = NumberFormat("#,###", "id_ID");
    final bool isWin = widget.totalMoney >= 1000000000000;
    final String resultText = isWin ? "Selamat! Anda Menang" : "Anda Kalah";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          resultText,
          style: TextStyle(
            fontSize: textFont,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: spacingSmall),
        Text(
          'Pemain: ${Uri.decodeComponent(widget.playerName)}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: textFont * 0.9, color: Colors.black),
        ),
        SizedBox(height: spacingSmall),
        Container(
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.015,
            horizontal: screenWidth * 0.05,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Text(
            'Total Uang: Rp ${formatter.format(widget.totalMoney)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: textFont * 0.9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: spacingLarge),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/game');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Main Lagi',
              style: TextStyle(
                fontSize: buttonFont,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: spacingSmall),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go("/home");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Text(
              'Keluar',
              style: TextStyle(
                fontSize: buttonFont,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
