import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VoucherHuntScreen extends StatefulWidget {
  const VoucherHuntScreen({super.key});

  @override
  State<VoucherHuntScreen> createState() => _VoucherHuntScreenState();
}

class _VoucherHuntScreenState extends State<VoucherHuntScreen>
    with TickerProviderStateMixin {
  final _rng = Random();

  bool _loading = true;
  int _coins = 0;
  int _playsLeft = 0;
  DateTime _today = DateTime.now();

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadDailyState();
  }

  String _dateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<DocumentReference<Map<String, dynamic>>?> _dailyRef() async {
    final u = _user;
    if (u == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .collection('voucher_daily')
        .doc(_dateKey(_today));
  }

  Future<void> _loadDailyState() async {
    setState(() => _loading = true);
    final ref = await _dailyRef();
    if (ref == null) {
      setState(() => _loading = false);
      return;
    }

    final snap = await ref.get();
    if (!snap.exists) {
      // Mỗi ngày cho 5 lượt, 20 coins khởi tạo
      await ref.set({
        "coins": 20,
        "playsLeft": 5,
        "createdAt": FieldValue.serverTimestamp(),
      });
      setState(() {
        _coins = 20;
        _playsLeft = 5;
        _loading = false;
      });
      return;
    }

    final data = snap.data()!;
    setState(() {
      _coins = (data["coins"] ?? 0) as int;
      _playsLeft = (data["playsLeft"] ?? 0) as int;
      _loading = false;
    });
  }

  Future<bool> _consumePlay({int coinCost = 0}) async {
    if (_playsLeft <= 0) {
      _toast("Hết lượt chơi hôm nay!");
      return false;
    }
    if (_coins < coinCost) {
      _toast("Không đủ coins!");
      return false;
    }

    final ref = await _dailyRef();
    if (ref == null) return false;

    setState(() {
      _playsLeft -= 1;
      _coins -= coinCost;
    });

    await ref.set({
      "coins": _coins,
      "playsLeft": _playsLeft,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return true;
  }

  Future<void> _addCoins(int amount) async {
    final ref = await _dailyRef();
    if (ref == null) return;
    setState(() => _coins += amount);
    await ref.set({"coins": _coins}, SetOptions(merge: true));
  }

  Future<void> _grantVoucher({
    required String title,
    required String code,
    required int discountPercent,
    int maxDiscountK = 50,
    int minOrderK = 0,
    int expiresInDays = 7,
  }) async {
    final u = _user;
    if (u == null) return;

    final exp = DateTime.now().add(Duration(days: expiresInDays));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .collection('vouchers')
        .add({
      "title": title,
      "code": code,
      "discountPercent": discountPercent,
      "maxDiscountK": maxDiscountK,
      "minOrderK": minOrderK,
      "expiresAt": Timestamp.fromDate(exp),
      "createdAt": FieldValue.serverTimestamp(),
      "isUsed": false,
      "source": "voucher_hunt",
    });

    _showWinDialog(
      "🎉 Bạn trúng voucher!",
      "$title\nMã: $code\nGiảm: $discountPercent% (tối đa ${maxDiscountK}K)\nHSD: ${exp.day}/${exp.month}/${exp.year}",
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showWinDialog(String title, String desc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  String _randomVoucherCode() {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    return List.generate(8, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  // ======= GAME 1: Lucky Wheel (đơn giản, không cần package) =======
  Future<void> _playLuckyWheel() async {
    if (!await _consumePlay(coinCost: 5)) return;

    // Tỉ lệ: coins nhiều hơn voucher, vẫn có voucher
    final roll = _rng.nextInt(100);
    if (roll < 50) {
      final c = 5 + _rng.nextInt(15);
      await _addCoins(c);
      _showWinDialog("🪙 Bạn nhận coins", "+$c coins");
      return;
    }
    if (roll < 85) {
      final discount = [5, 8, 10][_rng.nextInt(3)];
      await _grantVoucher(
        title: "Voucher giảm $discount%",
        code: "SHOE-${_randomVoucherCode()}",
        discountPercent: discount,
        maxDiscountK: 50,
        minOrderK: 0,
        expiresInDays: 7,
      );
      return;
    }
    // jackpot
    await _grantVoucher(
      title: "JACKPOT 15%",
      code: "JACK-${_randomVoucherCode()}",
      discountPercent: 15,
      maxDiscountK: 120,
      minOrderK: 300,
      expiresInDays: 5,
    );
  }

  // ======= GAME 2: Scratch Card =======
  Future<void> _playScratch() async {
    if (!await _consumePlay(coinCost: 3)) return;

    final roll = _rng.nextInt(100);
    if (roll < 60) {
      final c = 3 + _rng.nextInt(8);
      await _addCoins(c);
      _showWinDialog("🎫 Cào trúng coins", "+$c coins");
      return;
    }
    final discount = [5, 7, 10][_rng.nextInt(3)];
    await _grantVoucher(
      title: "Cào trúng giảm $discount%",
      code: "SCR-${_randomVoucherCode()}",
      discountPercent: discount,
      maxDiscountK: 60,
      minOrderK: 0,
      expiresInDays: 10,
    );
  }

  // ======= GAME 3: Memory Match =======
  Future<void> _playMemory() async {
    if (!await _consumePlay(coinCost: 4)) return;

    // mô phỏng: random “đúng/không” như game trí nhớ (bạn có thể làm UI lật thẻ sau)
    final win = _rng.nextBool();
    if (!win) {
      _showWinDialog("🧠 Chưa trúng", "Bạn chưa ghép đúng cặp. Thử lại nhé!");
      return;
    }

    final discount = [8, 10, 12][_rng.nextInt(3)];
    await _grantVoucher(
      title: "Ghép thẻ trúng $discount%",
      code: "MEM-${_randomVoucherCode()}",
      discountPercent: discount,
      maxDiscountK: 80,
      minOrderK: 150,
      expiresInDays: 7,
    );
  }

  // ======= GAME 4: Gift Smash =======
  Future<void> _playGiftSmash() async {
    if (!await _consumePlay(coinCost: 2)) return;

    final roll = _rng.nextInt(100);
    if (roll < 70) {
      final c = 2 + _rng.nextInt(6);
      await _addCoins(c);
      _showWinDialog("🎁 Đập hộp ra coins", "+$c coins");
      return;
    }
    final discount = [5, 8, 10][_rng.nextInt(3)];
    await _grantVoucher(
      title: "Đập hộp trúng $discount%",
      code: "GIFT-${_randomVoucherCode()}",
      discountPercent: discount,
      maxDiscountK: 70,
      minOrderK: 100,
      expiresInDays: 6,
    );
  }

  // ======= GAME 5: Speed Quiz =======
  Future<void> _playSpeedQuiz() async {
    if (!await _consumePlay(coinCost: 1)) return;

    final questions = [
      {
        "q": "Nike có logo tên gì?",
        "a": ["Jumpman", "Swoosh", "Trifoil"],
        "correct": 1
      },
      {
        "q": "Adidas thường gắn với biểu tượng?",
        "a": ["Trifoil", "Swoosh", "Puma Cat"],
        "correct": 0
      },
      {
        "q": "Jordan logo là?",
        "a": ["Jumpman", "Cá sấu", "Ngôi sao"],
        "correct": 0
      },
    ];

    final item = questions[_rng.nextInt(questions.length)];
    final q = item["q"] as String;
    final answers = (item["a"] as List).cast<String>();
    final correct = item["correct"] as int;

    int? picked;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚡ Quiz 5 giây"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            for (int i = 0; i < answers.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(answers[i]),
                onTap: () {
                  picked = i;
                  Navigator.pop(context);
                },
              )
          ],
        ),
      ),
    );

    if (picked == null) return;
    if (picked == correct) {
      await _grantVoucher(
        title: "Quiz đúng! Giảm 8%",
        code: "QUIZ-${_randomVoucherCode()}",
        discountPercent: 8,
        maxDiscountK: 60,
        minOrderK: 120,
        expiresInDays: 7,
      );
    } else {
      _showWinDialog("❌ Sai rồi", "Bạn nhận 3 coins khích lệ!");
      await _addCoins(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Săn Voucher",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopStatus(
              coins: _coins,
              playsLeft: _playsLeft,
              onRefresh: _loadDailyState,
            ),
            const SizedBox(height: 16),
            const Text(
              "Chọn trò chơi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _GameCard(
              title: "Vòng quay may mắn",
              subtitle: "Tốn 5 coins • Tỉ lệ jackpot thấp nhưng xịn",
              icon: Icons.casino_outlined,
              onTap: _playLuckyWheel,
            ),
            _GameCard(
              title: "Cào vé bí ẩn",
              subtitle: "Tốn 3 coins • Trúng coins/voucher ngẫu nhiên",
              icon: Icons.confirmation_number_outlined,
              onTap: _playScratch,
            ),
            _GameCard(
              title: "Lật thẻ trí nhớ",
              subtitle: "Tốn 4 coins • Thắng sẽ được voucher mạnh hơn",
              icon: Icons.grid_view_rounded,
              onTap: _playMemory,
            ),
            _GameCard(
              title: "Đập hộp quà",
              subtitle: "Tốn 2 coins • Nhanh gọn, vui tay",
              icon: Icons.card_giftcard,
              onTap: _playGiftSmash,
            ),
            _GameCard(
              title: "Quiz 5 giây",
              subtitle: "Tốn 1 coin • Trả lời đúng nhận voucher",
              icon: Icons.bolt,
              onTap: _playSpeedQuiz,
            ),

            const SizedBox(height: 16),
            _HintBox(),
          ],
        ),
      ),
    );
  }
}

class _TopStatus extends StatelessWidget {
  final int coins;
  final int playsLeft;
  final VoidCallback onRefresh;

  const _TopStatus({
    required this.coins,
    required this.playsLeft,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatPill(
              icon: Icons.monetization_on_outlined,
              label: "Coins",
              value: coins.toString(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatPill(
              icon: Icons.local_fire_department_outlined,
              label: "Lượt hôm nay",
              value: playsLeft.toString(),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

      ),
    );
  }
}
