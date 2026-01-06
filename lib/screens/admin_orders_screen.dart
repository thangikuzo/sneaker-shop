// lib/screens/admin_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/shoe_model.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return "Chờ xác nhận";
      case 'processing':
        return "Đang xử lý";
      case 'shipped':
        return "Đang giao";
      case 'delivered':
        return "Đã giao";
      case 'cancelled':
        return "Đã hủy";
      default:
        return "Chờ xác nhận";
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.purple;
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(String docId, String newStatus, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật trạng thái thành công!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý đơn hàng"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false, // ← BỎ NÚT TRỞ VỀ (BACK BUTTON)
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có đơn hàng nào"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = data['orderId'] ?? 'N/A';
              final name = data['name'] ?? 'Khách lẻ';
              final phone = data['phone'] ?? '';
              final address = data['address'] ?? '';
              final totalVND = (data['totalVND'] as num?)?.toDouble() ?? 0;
              final status = data['status'] ?? 'pending';
              final timestamp = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final date = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);

              final items = (data['items'] as List<dynamic>?) ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  title: Text("Đơn $orderId - $name", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$date • ${Shoe.vndFormat.format(totalVND)}"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(getStatusText(status), style: TextStyle(color: getStatusColor(status), fontWeight: FontWeight.bold)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("SĐT: $phone"),
                          Text("Địa chỉ: $address"),
                          const SizedBox(height: 12),
                          const Text("Sản phẩm:", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...items.map((item) => ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item['shoeImage'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(item['shoeName']),
                            subtitle: Text("Size: ${item['selectedSize']} • SL: ${item['quantity']}"),
                          )),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (status == 'pending') ...[
                                ElevatedButton(
                                  onPressed: () => _updateStatus(doc.id, 'processing', context),
                                  child: const Text("Xác nhận & Xử lý"),
                                ),
                                ElevatedButton(
                                  onPressed: () => _updateStatus(doc.id, 'cancelled', context),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text("Hủy đơn"),
                                ),
                              ] else if (status == 'processing')
                                ElevatedButton(
                                  onPressed: () => _updateStatus(doc.id, 'shipped', context),
                                  child: const Text("Giao hàng"),
                                )
                              else if (status == 'shipped')
                                  ElevatedButton(
                                    onPressed: () => _updateStatus(doc.id, 'delivered', context),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text("Hoàn thành"),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}