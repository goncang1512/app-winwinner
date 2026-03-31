import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState extends ChangeNotifier {
  String playerName = '';
  int hp = 3;
  int money = 0;
  final token = null;

  // set nama player
  void setPlayerName(String name) {
    playerName = name;
    saveName();
    notifyListeners();
  }

  // tambah uang
  void addMoney(int amount) {
    money += amount;
    notifyListeners();
  }

  // kurangi HP, return true kalau masih hidup, false kalau game over
  bool loseHp() {
    if (hp > 0) hp--;
    notifyListeners();
    return hp > 0;
  }

  bool get isAlive => hp > 0;

  void resetGame() {
    money = 0;
    hp = 3;
    playerName = '';
    notifyListeners();
  }

  // simpan nama ke lokal
  Future<void> saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerName', playerName);
  }

  // load nama dari lokal
  Future<void> loadName() async {
    final prefs = await SharedPreferences.getInstance();
    playerName = prefs.getString('playerName') ?? '';
    notifyListeners();
  }
}
