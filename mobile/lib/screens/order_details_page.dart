import 'package:flutter/material.dart';
import 'package:trinity/screens/order_product_card.dart';
import 'package:trinity/utils/api/detalscommand.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({required this.orderId, super.key});

  @override
  OrderDetailsPageState createState() => OrderDetailsPageState();
}

class OrderDetailsPageState extends State<OrderDetailsPage> {
  late Map<String, dynamic> orderDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final orderDetailsApi = OrderDetailsApi();
      final response = await orderDetailsApi.getOrderDetails(widget.orderId);

      debugPrint("Réponse de l'API : $response");

      if (response.containsKey('products') && response['products'] != null) {
        setState(() {
          orderDetails = response;
        });
      } else {
        debugPrint("Aucune clé 'products' dans la réponse");
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des détails de la commande: $e");
      setState(() {
        orderDetails = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orderDetails.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Détails de la commande')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    var products = [];
    double totalAmount = 0.0;
    if (orderDetails.containsKey('products') &&
        orderDetails['products'] != null) {
      debugPrint(orderDetails['products'].toString());
      products =
          orderDetails['products'].map((productData) {
            double total = productData['price'].toDouble();
            totalAmount += total;
            return {
              'name': productData['name'],
              'description': productData['description'],
              'image': productData['image'],
              'price': productData['price'],
              'quantity': productData['quantity'],
              'total': total,
            };
          }).toList();
    } else {
      debugPrint("Aucun produit trouvé dans la réponse");
    }

    if (products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Détails de la commande')),
        body: Center(
          child: Text(
            'Il n\'y a actuellement aucun produit dans cette commande.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Détails de la commande')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return OrderProductCard(product: products[index]);
              },
            ),
          ),
          Divider(color: Colors.black),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$totalAmount €',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
