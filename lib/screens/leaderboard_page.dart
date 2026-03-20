import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uts/states/http_api.dart';
import '../widgets/back_button.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final ApiService api = ApiService();

  bool isLoading = true;
  List<Map<String, dynamic>> leaderboard = [];

  final formatter = NumberFormat("#,###", "id_ID");

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      setState(() => isLoading = true);

      final res = await api.get('/score/leaderboard');

      if (res is List) {
        leaderboard = List<Map<String, dynamic>>.from(res);
      } else if (res is Map && res['result'] is List) {
        leaderboard = List<Map<String, dynamic>>.from(res['result']);
      } else {
        throw Exception("Format leaderboard tidak sesuai");
      }
    } catch (e) {
      print("ERROR LEADERBOARD: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil leaderboard")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFB300),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        elevation: 0,
        leading: BackButtonWidget(
          onPressed: () {
            context.push("/home");
          },
        ),
        title: const Text(
          "Leaderboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : leaderboard.isEmpty
          ? const Center(child: Text("Belum ada data"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final item = leaderboard[index];
                final rank = index + 1;

                final username = item['username'] ?? 'Unknown';
                final score = item['score'] ?? 0;

                return _buildLeaderboardItem(rank, username, score);
              },
            ),
    );
  }

  Widget _buildLeaderboardItem(int rank, String username, int score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: rank <= 3 ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          // RANK
          CircleAvatar(
            backgroundColor: rank <= 3 ? Colors.yellow : Colors.black,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // USERNAME
          Expanded(
            child: Text(
              username,
              style: TextStyle(
                color: rank <= 3 ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // SCORE
          Text(
            'Rp ${formatter.format(score)}',
            style: TextStyle(
              color: rank <= 3 ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
