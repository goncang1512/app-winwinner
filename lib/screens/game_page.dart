import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
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
  int currentQuestionIndex = 0;
  int totalQuestions = 0;

  // ✅ Satu AudioPlayer saja untuk semua sound
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isLoading = true;
  bool _gameStartSoundDone = false; // ✅ Flag agar game-dimulai hanya sekali

  List<Map<String, dynamic>> remainingQuestions = [];
  Map<String, dynamic>? currentQuestion;
  List<String> currentOptions = [];

  bool usedFifty = false;
  bool usedRefresh = false;

  int timeLeft = 20;
  Timer? timer;

  List<int> removedOptions = [];
  bool _isProcessing = false;

  final formatter = NumberFormat("#,###", "id_ID");

  @override
  void initState() {
    super.initState();
    _setupAudio();
    _fetchQuestions();
  }

  // ================= AUDIO SETUP =================
  Future<void> _playCorrect() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.setVolume(0.9);

      await _audioPlayer.play(AssetSource('sound/jawaban-benar.mpeg'));
    } catch (e) {
      debugPrint('Correct sound error: $e');
    }
  }

  Future<void> _playWrong() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.setVolume(0.9);
      await _audioPlayer.play(AssetSource('sound/jawaban-salah.mp3'));
    } catch (e) {
      debugPrint('Wrong sound error: $e');
    }
  }

  Future<void> _setupAudio() async {
    // Set audio context agar tidak bentrok dengan sistem
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gain,
          usageType: AndroidUsageType.game,
          contentType: AndroidContentType.music,
          isSpeakerphoneOn: false,
          stayAwake: false,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {},
        ),
      ),
    );
  }

  // ================= SOUND =================
  Future<void> _playGameStart() async {
    if (_gameStartSoundDone) return;
    _gameStartSoundDone = true;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.setVolume(0.6);
      await _audioPlayer.play(AssetSource('sound/game-dimulai.mp3'));

      // Tunggu sampai selesai baru lanjut ke heartbeat
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      debugPrint('Game start sound error: $e');
    }
  }

  Future<void> _playHeartbeat() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sound/detak-jantung.mpeg'));
    } catch (e) {
      debugPrint('Heartbeat sound error: $e');
    }
  }

  Future<void> _stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Stop sound error: $e');
    }
  }

  // ================= API =================
  Future<void> _fetchQuestions() async {
    try {
      setState(() => isLoading = true);

      final res = await api.get('/question');

      if (res is List) {
        remainingQuestions = List<Map<String, dynamic>>.from(res);
      } else if (res is Map && res['result'] is List) {
        remainingQuestions = List<Map<String, dynamic>>.from(res['result']);
      } else {
        throw Exception("Format API tidak sesuai");
      }

      _nextQuestion();
      totalQuestions = remainingQuestions.length + 1;
    } catch (e) {
      debugPrint("ERROR FETCH: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal mengambil soal")));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // ✅ Urutan: game-dimulai selesai dulu → baru heartbeat + timer
          await _playGameStart();
          if (!mounted) return;
          startTimer();
          await _playHeartbeat();
        });
      }
    }
  }

  // ================= TIMER =================
  void startTimer() {
    timer?.cancel();
    setState(() => timeLeft = 20);

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        _handleWrongAnswer(reason: 'Waktu habis!');
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
    currentOptions = List<String>.from(nextQ['options'] ?? []);
    currentOptions.shuffle();
    removedOptions.clear();

    // ✅ Reset lifeline tiap soal baru
    usedFifty = false;
    usedRefresh = false;

    // ✅ Tambah counter
    currentQuestionIndex++;

    if (mounted) setState(() {});
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
    startTimer();
    _playHeartbeat();
  }

  // ================= HANDLE WRONG / TIME OUT =================
  void _handleWrongAnswer({required String reason}) {
    if (_isProcessing) return;
    _isProcessing = true;

    timer?.cancel();
    _stopSound();

    final gameState = context.read<GameState>();
    final stillAlive = gameState.loseHp();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stillAlive
                ? '$reason Sisa HP: ${gameState.hp} ❤️'
                : '$reason Game Over!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // ✅ Tunggu sound salah selesai dulu, baru lanjut
    _playWrong().then((_) {
      _audioPlayer.onPlayerComplete.first.then((_) {
        if (!mounted) return;
        _isProcessing = false;

        if (stillAlive) {
          _nextQuestion();
          startTimer();
          _playHeartbeat();
        } else {
          endGame();
        }
      });
    });
  }

  // ================= CHECK ANSWER =================
  void checkAnswer(String selectedOption) {
    if (_isProcessing || currentQuestion == null) return;

    timer?.cancel();
    _stopSound(); // Stop heartbeat

    final correctAnswer = currentQuestion!['answer'];
    final gameState = context.read<GameState>();

    if (selectedOption == correctAnswer) {
      _isProcessing = true;

      final point = (currentQuestion!['point'] ?? 0) as int;
      gameState.money += point;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Benar! +${formatter.format(point)} | Total: Rp ${formatter.format(gameState.money)}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // ✅ Play dulu, tunggu selesai, baru lanjut
      _playCorrect().then((_) {
        _audioPlayer.onPlayerComplete.first.then((_) {
          if (!mounted) return;
          _isProcessing = false;
          _nextQuestion();
          startTimer();
          _playHeartbeat();
        });
      });
    } else {
      _isProcessing = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salah!'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final gameState2 = context.read<GameState>();
      final stillAlive = gameState2.loseHp();

      // ✅ Play dulu, tunggu selesai, baru lanjut — TIDAK panggil _handleWrongAnswer
      _playWrong().then((_) {
        _audioPlayer.onPlayerComplete.first.then((_) {
          if (!mounted) return;
          _isProcessing = false;

          if (stillAlive) {
            _nextQuestion();
            startTimer();
            _playHeartbeat();
          } else {
            endGame();
          }
        });
      });
    }
  }

  // ================= END GAME =================
  void endGame() async {
    timer?.cancel();
    await _stopSound(); // ✅ Stop semua sound

    final session = await AuthService.getSession();
    if (!mounted) return;

    final gameState = context.read<GameState>();
    final playerName = session?['result']['username'] ?? 'Guest';
    final totalMoney = gameState.money;
    final bool isWin = totalMoney >= 1000000000000;

    await api.post("/score/update-score", {"score": totalMoney});

    gameState.resetGame();

    if (mounted) {
      context.go(
        '/end/${Uri.encodeComponent(playerName)}/$totalMoney',
        extra: {'isWin': isWin},
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ================= HP WIDGET =================
  Widget _buildHpWidget(int hp) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i < hp;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            active ? Icons.favorite : Icons.favorite_border,
            color: active ? Colors.red : Colors.white54,
            size: 26,
          ),
        );
      }),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    if (isLoading || currentQuestion == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFB300),
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final hp = context.watch<GameState>().hp;
    final timerSize = 35.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFB300),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        elevation: 0,
        leading: BackButtonWidget(
          onPressed: () {
            timer?.cancel();
            _stopSound();
            final gameState = context.read<GameState>();
            gameState.resetGame();
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: _buildHpWidget(hp)),
          ),
        ],
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

  Widget _buildNarrowLayout(BuildContext context, BoxConstraints constraints) {
    final money = context.watch<GameState>().money;
    final q = currentQuestion!;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _helpButton(
                  '$currentQuestionIndex:$totalQuestions',
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

  Widget _buildWideLayout(BuildContext context, BoxConstraints constraints) {
    final money = context.watch<GameState>().money;
    final q = currentQuestion!;

    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final logoSize = screenWidth * 0.12;
    final fontSize = screenWidth * 0.02;
    final buttonFont = screenWidth * 0.022;
    final spacingMedium = screenHeight * 0.03;
    final helpButtonDiameter = screenWidth * 0.07;

    return Row(
      children: [
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
