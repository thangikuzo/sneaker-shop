// lib/screens/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/shoe_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lịch sử đơn hàng")),
        body: const Center(child: Text("Vui lòng đăng nhập để xem đơn hàng")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử đơn hàng"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Chưa có đơn hàng nào", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("Hãy mua sắm ngay nào! 😊", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final data = orderDoc.data() as Map<String, dynamic>;
              final orderId = data['orderId'] ?? 'SNK???';
              final totalVND = (data['totalVND'] as num?)?.toDouble() ?? 0;
              final status = data['status'] ?? 'pending';
              final timestamp = (data['createdAt'] as Timestamp?) ?? Timestamp.now();
              final createdAt = timestamp.toDate();
              final date = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

              final items = (data['items'] as List<dynamic>?) ?? [];

              String statusText;
              Color statusColor;
              switch (status) {
                case 'processing':
                  statusText = "Đang xử lý";
                  statusColor = Colors.orange;
                  break;
                case 'shipped':
                  statusText = "Đang giao";
                  statusColor = Colors.blue;
                  break;
                case 'delivered':
                  statusText = "Đã giao";
                  statusColor = Colors.green;
                  break;
                case 'cancelled':
                  statusText = "Đã hủy";
                  statusColor = Colors.red;
                  break;
                default:
                  statusText = "Chờ xác nhận";
                  statusColor = Colors.purple;
              }

              // Cho phép chỉnh sửa/hủy nếu pending và dưới 30 phút
              final canEditOrCancel = status == 'pending' &&
                  DateTime.now().difference(createdAt).inMinutes < 30;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(
                          orderData: data,
                          orderId: orderId,
                          orderDocId: orderDoc.id, // Truyền ID document để cập nhật
                          canEdit: canEditOrCancel,
                        ),
                      ),
                    ).then((_) => setState(() {})); // Refresh lại sau khi quay về
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Mã đơn: $orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Thời gian: $date", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        if (items.isNotEmpty)
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: items[0]['shoeImage'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text("${items.length} sản phẩm", style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Tổng tiền", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(Shoe.vndFormat.format(totalVND), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                          ],
                        ),
                        if (canEditOrCancel)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OrderDetailScreen(
                                            orderData: data,
                                            orderId: orderId,
                                            orderDocId: orderDoc.id,
                                            canEdit: true,
                                          ),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
                                    child: const Text("CHỈNH SỬA THÔNG TIN"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Hủy đơn hàng?"),
                                          content: const Text("Bạn chắc chắn muốn hủy đơn này?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Không")),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hủy đơn", style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await FirebaseFirestore.instance.collection('orders').doc(orderDoc.id).update({'status': 'cancelled'});
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đơn hàng đã hủy")));
                                      }
                                    },
                                    child: const Text("HỦY ĐƠN"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Màn hình chi tiết + chỉnh sửa thông tin giao hàng
class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String orderId;
  final String orderDocId;
  final bool canEdit;

  const OrderDetailScreen({
    super.key,
    required this.orderData,
    required this.orderId,
    required this.orderDocId,
    this.canEdit = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.orderData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.orderData['phone'] ?? '');
    _addressController = TextEditingController(text: widget.orderData['address'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderDocId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thông tin thành công!")));
      Navigator.pop(context); // Quay về danh sách
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.orderData['items'] as List<dynamic>?) ?? [];
    final totalVND = (widget.orderData['totalVND'] as num?)?.toDouble() ?? 0;
    final timestamp = (widget.orderData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn ${widget.orderId}"),
        actions: widget.canEdit
            ? [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
          )
        ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Thông tin giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    enabled: widget.canEdit,
                    decoration: const InputDecoration(labelText: "Người nhận"),
                  ),
                  TextField(
                    controller: _phoneController,
                    enabled: widget.canEdit,
                    decoration: const InputDecoration(labelText: "Số điện thoại"),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    controller: _addressController,
                    enabled: widget.canEdit,
                    decoration: const InputDecoration(labelText: "Địa chỉ giao hàng"),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text("Sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: item['shoeImage'], width: 70, height: 70, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['shoeName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Size: ${item['selectedSize']}"),
                        Text("SL: ${item['quantity']}"),
                      ],
                    ),
                  ),
                  Text(Shoe.vndFormat.format((item['totalPriceUSD'] as num) * Shoe.usdToVndRate)),
                ],
              ),
            )),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Tổng tiền"), Text(Shoe.vndFormat.format(totalVND), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange))]),
                  const SizedBox(height: 8),
                  Text("Ngày đặt: $date", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            if (widget.canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("LƯU THAY ĐỔI"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}