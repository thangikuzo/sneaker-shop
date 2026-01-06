// File: lib/screens/chat_bot_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database.dart';
import '../models/shoe_model.dart';
import 'detail_screen.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService db = DatabaseService();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Chào bạn 👋\nMình là trợ lý sneaker đây!\nBạn cần tư vấn size giày, giá tiền hay tìm mẫu nào đẹp không ạ?",
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final String userText = _controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: userText, isUser: true));
      _controller.clear();
    });
    _scrollToBottom();

    final _BotResponse response = await _processMessage(userText);

    setState(() {
      _messages.add(_ChatMessage(text: response.text, isUser: false));
      if (response.shoes.isNotEmpty) {
        for (final shoe in response.shoes) {
          _messages.add(_ChatMessage(shoe: shoe, isProductCard: true, text: ''));
        }
        _messages.add(_ChatMessage(
          text: "\nBạn thích mẫu nào nhất? Mình tư vấn thêm nhé ❤️",
          isUser: false,
        ));
      }
    });
    _scrollToBottom();
  }

  // Xử lý tin nhắn dựa trên từ khóa (không cần dataset)
  Future<_BotResponse> _processMessage(String message) async {
    final String normalized = message.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // xóa dấu câu
        .replaceAll('á', 'a').replaceAll('à', 'a').replaceAll('ả', 'a').replaceAll('ã', 'a').replaceAll('ạ', 'a')
        .replaceAll('ă', 'a').replaceAll('â', 'a')
        .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ẻ', 'e').replaceAll('ẽ', 'e').replaceAll('ẹ', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i').replaceAll('ì', 'i').replaceAll('ỉ', 'i').replaceAll('ĩ', 'i').replaceAll('ị', 'i')
        .replaceAll('ó', 'o').replaceAll('ò', 'o').replaceAll('ỏ', 'o').replaceAll('õ', 'o').replaceAll('ọ', 'o')
        .replaceAll('ô', 'o').replaceAll('ơ', 'o')
        .replaceAll('ú', 'u').replaceAll('ù', 'u').replaceAll('ủ', 'u').replaceAll('ũ', 'u').replaceAll('ụ', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ý', 'y').replaceAll('ỳ', 'y').replaceAll('ỷ', 'y').replaceAll('ỹ', 'y').replaceAll('ỵ', 'y')
        .replaceAll('đ', 'd');

    final List<Shoe> allShoes = await _getAllShoes();

    // 1. Tư vấn size theo chiều dài chân
    final RegExp lengthReg = RegExp(r'(\d{2,3}(\.\d)?)\s*(cm|centimet)');
    final Match? lengthMatch = lengthReg.firstMatch(normalized);
    if (lengthMatch != null) {
      final double? lengthCm = double.tryParse(lengthMatch.group(1)!);
      if (lengthCm != null && lengthCm >= 20 && lengthCm <= 32) {
        final int recommendedSize = _getRecommendedSize(lengthCm);
        final List<Shoe> shoes = allShoes.where((s) => s.sizes.contains(recommendedSize)).toList();
        if (shoes.isEmpty) {
          return _BotResponse(
            text: "Chân bạn dài **$lengthCm cm** → nên mang **size $recommendedSize** là vừa chân nhất ạ! 👟\n\nRất tiếc hiện chưa có mẫu nào size này 😔\nBạn thử size ${recommendedSize - 1} hoặc ${recommendedSize + 1} nhé!",
          );
        }
        return _BotResponse(
          text: "Chân bạn dài **$lengthCm cm** → nên mang **size $recommendedSize** là vừa nhất ạ! 👟\n\nDưới đây là các mẫu hiện có size $recommendedSize:",
          shoes: shoes,
        );
      }
    }

    // 2. Hỏi size cụ thể
    final RegExp sizeReg = RegExp(r'size\s*(\d{2})');
    final Match? sizeMatch = sizeReg.firstMatch(normalized);
    if (sizeMatch != null) {
      final int? size = int.tryParse(sizeMatch.group(1)!);
      if (size != null) {
        final List<Shoe> shoes = allShoes.where((s) => s.sizes.contains(size)).toList();
        if (shoes.isEmpty) {
          return _BotResponse(text: "Hiện tại chưa có mẫu nào size $size ạ 😔\nBạn muốn thử size ${size - 1} hoặc ${size + 1} không?");
        }
        return _BotResponse(text: "Tuyệt! Đây là các mẫu đang có **size $size**:", shoes: shoes);
      }
    }

    // 3. Hỏi giá hoặc tên sản phẩm cụ thể
    for (final Shoe shoe in allShoes) {
      final String shoeNameNorm = shoe.name.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      if (normalized.contains(shoeNameNorm) || normalized.contains(shoeNameNorm.split(' ').first)) {
        return _BotResponse(
          text: "Đây là thông tin về **${shoe.name}**:\nGiá: **${shoe.priceVND}**\nCó sẵn size: ${shoe.sizesDisplay}",
          shoes: [shoe],
        );
      }
    }

    // 4. Hỏi theo thương hiệu
    final List<String> brands = ['nike', 'adidas', 'vans', 'puma', 'jordan'];
    for (final String brand in brands) {
      if (normalized.contains(brand)) {
        final List<Shoe> shoes = allShoes.where((s) => s.name.toLowerCase().contains(brand)).toList();
        if (shoes.isNotEmpty) {
          return _BotResponse(text: "Đây là các mẫu $brand hot nhất hiện tại:", shoes: shoes);
        }
      }
    }

    // 5. Chính sách phổ biến
    if (normalized.contains('cod') || normalized.contains('ship') || normalized.contains('giao hang')) {
      return _BotResponse(text: "Có hỗ trợ thanh toán khi nhận hàng (COD) toàn quốc ạ!\nPhí ship: 30.000 ₫");
    }
    if (normalized.contains('doi') || normalized.contains('tra') || normalized.contains('doi tra')) {
      return _BotResponse(text: "Được đổi trả trong 30 ngày nếu lỗi nhà sản xuất hoặc không vừa size ạ!");
    }
    if (normalized.contains('giam gia') || normalized.contains('khuyen mai') || normalized.contains('voucher')) {
      return _BotResponse(text: "Hiện có mã **SHOPEE10** giảm 100.000 ₫ và **FREESHIP** miễn phí vận chuyển ạ!");
    }

    // Fallback
    return _BotResponse(
      text: "Rất tiếc mình chưa hiểu câu hỏi của bạn 😅\nBạn có thể hỏi:\n• Chân dài bao nhiêu cm thì mang size nào?\n• Size XX có giày nào không?\n• Giày Nike/Vans giá bao nhiêu?\n• Có COD không?",
    );
  }

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
    return 45;
  }

  Future<List<Shoe>> _getAllShoes() async {
    try {
      final snapshot = await db.sneakers.first;
      return snapshot;
    } catch (e) {
      return [];
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Trợ lý Sneaker"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg.isProductCard && msg.shoe != null) {
                  return _ProductCard(shoe: msg.shoe!);
                }
                return _Bubble(text: msg.text, isUser: msg.isUser);
              },
            ),
          ),
          _InputBar(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}

// Helper classes
class _BotResponse {
  final String text;
  final List<Shoe> shoes;
  _BotResponse({required this.text, this.shoes = const []});
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final Shoe? shoe;
  final bool isProductCard;

  _ChatMessage({
    required this.text,
    this.isUser = false,
    this.shoe,
    this.isProductCard = false,
  });
}

// Card sản phẩm – bấm vào chuyển sang DetailScreen
class _ProductCard extends StatelessWidget {
  final Shoe shoe;

  const _ProductCard({required this.shoe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(shoe: shoe)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 0, right: 60),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            Hero(
              tag: shoe.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: shoe.image,
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const CircularProgressIndicator(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shoe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(shoe.priceVND, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text("Có sẵn size: ${shoe.sizesDisplay}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text("👆 Bấm để xem chi tiết", style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bubble tin nhắn
class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final Alignment align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? Colors.black : Colors.white,
          borderRadius: radius,
          boxShadow: const [BoxShadow(blurRadius: 10, offset: Offset(0, 2), color: Color(0x14000000))],
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15, height: 1.3),
        ),
      ),
    );
  }
}

// Thanh nhập tin nhắn
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 12, offset: Offset(0, -2), color: Color(0x14000000))],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: "Hỏi mình về size, giá tiền, mẫu giày...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.black)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              width: 46,
              child: ElevatedButton(
                onPressed: onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}