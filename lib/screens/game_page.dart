import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uts/states/auth_state.dart';
import 'package:uts/states/http_api.dart';
import '../states/game_state.dart';
import '../widgets/logo.dart';
import '../widgets/back_button.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final ApiService api = ApiService();

  bool isLoading = true;

  List<Map<String, dynamic>> remainingQuestions = [];
  Map<String, dynamic>? currentQuestion;
  List<String> currentOptions = [];

  bool usedFifty = false;
  bool usedRefresh = false;

  int timeLeft = 20;
  Timer? timer;

  List<int> removedOptions = [];
  bool isAnswered = false;

  final formatter = NumberFormat("#,###", "id_ID");

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  // ================= API =================
  Future<void> _fetchQuestions() async {
    try {
      setState(() => isLoading = true);

      final res = await api.get('/question');

      // HANDLE kalau response object / list
      if (res is List) {
        remainingQuestions = List<Map<String, dynamic>>.from(res);
      } else if (res is Map && res['result'] is List) {
        remainingQuestions = List<Map<String, dynamic>>.from(res['result']);
      } else {
        throw Exception("Format API tidak sesuai");
      }

      _nextQuestion();
      startTimer();
    } catch (e) {
      print("ERROR FETCH: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal mengambil soal")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= TIMER =================
  void startTimer() {
    timer?.cancel();
    timeLeft = 20;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        endGame();
      }
    });
  }

  // ================= NEXT QUESTION =================
  void _nextQuestion() {
    if (remainingQuestions.isEmpty) {
      endGame();
      return;
    }

    final random = Random();
    final nextQ = remainingQuestions[random.nextInt(remainingQuestions.length)];

    remainingQuestions.remove(nextQ);

    currentQuestion = nextQ;

    // FIX TYPE SAFE
    currentOptions = List<String>.from(nextQ['options'] ?? []);

    currentOptions.shuffle();

    removedOptions.clear();

    setState(() {});
  }

  // ================= LIFELINE =================
  void useFifty() {
    if (usedFifty || currentQuestion == null) return;

    usedFifty = true;

    final correct = currentQuestion!['answer'];
    final wrongOptions = currentOptions.where((o) => o != correct).toList();

    wrongOptions.shuffle();

    removedOptions = [];

    for (int i = 0; i < currentOptions.length; i++) {
      if (wrongOptions.take(2).contains(currentOptions[i])) {
        removedOptions.add(i);
      }
    }

    setState(() {});
  }

  void useRefresh() {
    if (usedRefresh) return;

    usedRefresh = true;

    _nextQuestion();
    timeLeft = 20;

    setState(() {});
  }

  // ================= CHECK ANSWER =================
  void checkAnswer(String selectedOption) {
    if (isAnswered || currentQuestion == null) return;

    isAnswered = true;

    final correctAnswer = currentQuestion!['answer'];
    final gameState = context.read<GameState>();

    if (selectedOption == correctAnswer) {
      final point = (currentQuestion!['point'] ?? 0) as int;

      gameState.money += point;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Benar! +${formatter.format(point)} | Total: Rp ${formatter.format(gameState.money)}',
          ),
          duration: const Duration(seconds: 1),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        isAnswered = false;
        timeLeft = 20;
        _nextQuestion();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salah! Permainan Berakhir'),
          duration: Duration(seconds: 1),
        ),
      );

      Future.delayed(const Duration(seconds: 1), endGame);
    }
  }

  // ================= END GAME =================
  void endGame() async {
    timer?.cancel();

    final session = await AuthService.getSession();
    final gameState = context.read<GameState>();

    final playerName = session?['result']['username'] ?? 'Guest';

    final totalMoney = gameState.money;

    final bool isWin = totalMoney >= 1000000000000;

    await api.post("/score/update-score", {
      "score": session?['result']['score'],
    });

    gameState.resetGame();

    context.go(
      '/end/${Uri.encodeComponent(playerName)}/$totalMoney',
      extra: {'isWin': isWin},
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    // ✅ LOADING FIX (ini yang kamu minta)
    if (isLoading || currentQuestion == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFB300),
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final timerSize = 35.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFB300),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        elevation: 0,
        leading: BackButtonWidget(
          onPressed: () {
            final gameState = context.read<GameState>();
            gameState.money = 0;
            context.go('/home');
          },
        ),
        centerTitle: true,
        title: Container(
          padding: EdgeInsets.all(timerSize * 0.3),
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Text(
            '$timeLeft',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: timerSize * 0.6,
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 650) {
            return _buildWideLayout(context, constraints);
          } else {
            return _buildNarrowLayout(context, constraints);
          }
        },
      ),
    );
  }

  //build layout untuk hp
  Widget _buildNarrowLayout(BuildContext context, BoxConstraints constraints) {
    final money = context.watch<GameState>().money;
    final q = currentQuestion!;

    // Ukuran dinamis
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final logoSize = screenHeight * 0.22;
    final fontSize = screenWidth * 0.04;
    final buttonFont = screenWidth * 0.042;
    final spacingSmall = screenHeight * 0.02;
    final spacingMedium = screenHeight * 0.03;
    final helpButtonDiameter = screenWidth * 0.20;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: logoSize,
              child: Logo(size: logoSize),
            ),
            SizedBox(height: spacingSmall),
            // bantuan
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _helpButton('50:50', usedFifty, useFifty, helpButtonDiameter),
                _helpButtonIcon(
                  Icons.refresh,
                  usedRefresh,
                  useRefresh,
                  helpButtonDiameter,
                ),
              ],
            ),
            SizedBox(height: spacingMedium),
            _moneyBox(money, fontSize, screenHeight, screenWidth),
            SizedBox(height: spacingSmall),
            _questionBox(q['question'], fontSize, screenWidth),
            SizedBox(height: spacingMedium),
            _answerButtons(screenHeight, currentOptions, buttonFont),
          ],
        ),
      ),
    );
  }

  //build layout untuk layar lebar
  Widget _buildWideLayout(BuildContext context, BoxConstraints constraints) {
    final money = context.watch<GameState>().money;
    final q = currentQuestion!;

    // Ukuran dinamis
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final logoSize = screenWidth * 0.12;
    final fontSize = screenWidth * 0.02;
    final buttonFont = screenWidth * 0.022;
    final spacingMedium = screenHeight * 0.03;

    final helpButtonDiameter = screenWidth * 0.07;

    return Row(
      children: [
        //SISI KIRI: INFO (Logo, Bantuan, Uang)
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.02),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Logo(size: logoSize),
                SizedBox(height: spacingMedium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _helpButton(
                      '50:50',
                      usedFifty,
                      useFifty,
                      helpButtonDiameter,
                    ),
                    _helpButtonIcon(
                      Icons.refresh,
                      usedRefresh,
                      useRefresh,
                      helpButtonDiameter,
                    ),
                  ],
                ),
                SizedBox(height: spacingMedium),
                _moneyBox(money, fontSize, screenHeight, screenWidth * 0.3),
              ],
            ),
          ),
        ),

        //SISI KANAN: AKSI (Pertanyaan, Jawaban)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _questionBox(q['question'], fontSize, screenWidth * 0.6),
                  SizedBox(height: spacingMedium),
                  _answerButtons(screenHeight, currentOptions, buttonFont),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _helpButton(
    String text,
    bool used,
    VoidCallback onPressed,
    double diameter,
  ) {
    return AnimatedOpacity(
      opacity: used ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: diameter,
        width: diameter,
        margin: EdgeInsets.symmetric(horizontal: diameter * 0.1),
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: TextButton(
          onPressed: used ? null : onPressed,
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: diameter * 0.30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _helpButtonIcon(
    IconData icon,
    bool used,
    VoidCallback onPressed,
    double diameter,
  ) {
    return AnimatedOpacity(
      opacity: used ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: diameter,
        width: diameter,
        margin: EdgeInsets.symmetric(horizontal: diameter * 0.1),
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: diameter * 0.5),
          onPressed: used ? null : onPressed,
        ),
      ),
    );
  }

  Widget _moneyBox(
    int money,
    double fontSize,
    double screenHeight,
    double screenWidth,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.01,
        horizontal: screenWidth * 0.06,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        'Rp ${formatter.format(money)}',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize * 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _questionBox(String question, double fontSize, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        question,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _answerButtons(
    double screenHeight,
    List<String> options,
    double buttonFont,
  ) {
    return Column(
      children: List.generate(options.length, (i) {
        final disabled = removedOptions.contains(i);
        final optionText = options[i];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.007),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: disabled ? null : () => checkAnswer(optionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: disabled ? Colors.grey.shade600 : Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
                elevation: 2,
              ),
              child: Text(
                '${String.fromCharCode(65 + i)}. $optionText',
                style: TextStyle(fontSize: buttonFont),
              ),
            ),
          ),
        );
      }),
    );
  }
}
