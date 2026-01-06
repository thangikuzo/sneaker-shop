// File: lib/screens/size_advisor_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database.dart';
import '../models/shoe_model.dart';
import 'detail_screen.dart';

class SizeAdvisorScreen extends StatefulWidget {
  const SizeAdvisorScreen({super.key});

  @override
  State<SizeAdvisorScreen> createState() => _SizeAdvisorScreenState();
}

class _SizeAdvisorScreenState extends State<SizeAdvisorScreen> {
  final TextEditingController _lengthController = TextEditingController();
  double? _footLength;
  int? _recommendedSize;
  List<Shoe> _recommendedShoes = [];
  bool _isLoading = false;

  final db = DatabaseService();

  // Bảng quy đổi chân → size EU
  int _getRecommendedSize(double lengthCm) {
    if (lengthCm <= 22.9) return 36;
    if (lengthCm <= 23.9) return 37;
    if (lengthCm <= 24.4) return 38;
    if (lengthCm <= 25.4) return 39;
    if (lengthCm <= 26.0) return 40;
    if (lengthCm <= 26.6) return 41;
    if (lengthCm <= 27.2) return 42;
    if (lengthCm <= 28.0) return 43;
    if (lengthCm <= 28.6) return 44;
    return 45; // lớn hơn
  }

  void _advise() async {
    final text = _lengthController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập chiều dài bàn chân")));
      return;
    }

    final length = double.tryParse(text);
    if (length == null || length < 20 || length > 32) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chiều dài chân hợp lệ từ 20-32 cm")));
      return;
    }

    setState(() {
      _isLoading = true;
      _footLength = length;
      _recommendedSize = _getRecommendedSize(length);
    });

    // Lấy tất cả giày và lọc có size phù hợp
    final snapshot = await db.sneakers.first;
    final allShoes = snapshot;
    final recommended = allShoes.where((shoe) => shoe.sizes.contains(_recommendedSize)).toList();

    setState(() {
      _recommendedShoes = recommended;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tư vấn size giày")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Đo chiều dài bàn chân của bạn (từ gót đến ngón dài nhất) và nhập vào đây để được tư vấn size phù hợp nhé!", style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _lengthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Chiều dài bàn chân (cm)",
                suffixText: "cm",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _advise,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("TƯ VẤN NGAY", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),

            const SizedBox(height: 30),
            if (_isLoading) const CircularProgressIndicator(),
            if (_recommendedSize != null && !_isLoading) ...[
              Text("Size giày phù hợp với bạn là: $_recommendedSize", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 10),
              Text("Dưới đây là các mẫu giày hiện có size $_recommendedSize:", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Expanded(
                child: _recommendedShoes.isEmpty
                    ? const Center(child: Text("Rất tiếc, hiện chưa có mẫu nào phù hợp 😔\nHãy thử size gần đó nhé!"))
                    : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.6, crossAxisSpacing: 16, mainAxisSpacing: 16),
                  itemCount: _recommendedShoes.length,
                  itemBuilder: (context, index) {
                    final shoe = _recommendedShoes[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(shoe: shoe))),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                        child: Column(
                          children: [
                            Expanded(child: CachedNetworkImage(imageUrl: shoe.image, fit: BoxFit.contain)),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shoe.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(shoe.priceVND, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                  Text("Có size $_recommendedSize", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}