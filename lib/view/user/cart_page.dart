import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter2/view/auth/login.dart';
import 'package:flutter2/view/user/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic>? _cartItems;
  Map<String, dynamic>? _userData;
  String? _token;
  bool _isLoading = true;
  String? _errorMessage;
  double _totalPrice = 0.0;

  Future<void> _saveLocalCart(List<dynamic> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_cart', jsonEncode(cart));
    setState(() {
      _cartItems = cart;
    });
    _recalculateTotal();
  }

  void _recalculateTotal() {
    double total = 0.0;
    if (_cartItems != null) {
      for (var item in _cartItems!) {
        final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
        final qty = (item['quantity'] is int) ? item['quantity'] as int : (item['quantity'] is num ? (item['quantity'] as num).toInt() : 1);
        total += price * qty;
      }
    }
    setState(() {
      _totalPrice = total;
    });
  }

  Future<void> _increaseQtyAt(int index) async {
    if (_cartItems == null) return;
    final item = Map<String, dynamic>.from(_cartItems![index]);
    item['quantity'] = (item['quantity'] ?? 1) + 1;
    final newCart = List<dynamic>.from(_cartItems!);
    newCart[index] = item;

    // Always persist to local_cart to allow editing
    await _saveLocalCart(newCart);
  }

  Future<void> _decreaseQtyAt(int index) async {
    if (_cartItems == null) return;
    final item = Map<String, dynamic>.from(_cartItems![index]);
    final currentQty = (item['quantity'] is int)
        ? item['quantity'] as int
        : (item['quantity'] is num ? (item['quantity'] as num).toInt() : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1);
    if (currentQty <= 1) {
      // If qty would go to 0, remove item
      await _deleteItemAt(index);
      return;
    }
    item['quantity'] = currentQty - 1;
    final newCart = List<dynamic>.from(_cartItems!);
    newCart[index] = item;
    await _saveLocalCart(newCart);
  }

  Future<void> _deleteItemAt(int index) async {
    if (_cartItems == null) return;
    final newCart = List<dynamic>.from(_cartItems!);
    newCart.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    if (newCart.isEmpty) {
      await prefs.remove('local_cart');
      setState(() {
        _cartItems = [];
        _totalPrice = 0.0;
      });
    } else {
      await _saveLocalCart(newCart);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    final prefs = await SharedPreferences.getInstance();
    // Check local cart first
    final localCartString = prefs.getString('local_cart');
    if (localCartString != null) {
      final List<dynamic> localCart = jsonDecode(localCartString);
      double total = 0.0;
      for (var item in localCart) {
        total += (item['price'] as num).toDouble() * (item['quantity'] ?? 1);
      }
      setState(() {
        _cartItems = localCart;
        _totalPrice = total;
        _isLoading = false;
      });
      return;
    }
    final userDataString = prefs.getString('user_data');
    final token = prefs.getString('auth_token');

    String userDataStringNonNull;
    String tokenNonNull;

    if (userDataString == null || token == null) {
      // Not logged in: navigate to LoginPage and wait for result.
      if (!mounted) return;
      final result = await Navigator.push<bool?>(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

      // If the login page returned true, attempt to reload auth info
      if (result == true) {
        final prefs2 = await SharedPreferences.getInstance();
        final userDataString2 = prefs2.getString('user_data');
        final token2 = prefs2.getString('auth_token');
        if (userDataString2 == null || token2 == null) {
          setState(() {
            _errorMessage = 'Please log in to view your cart';
            _isLoading = false;
          });
          return;
        }
        // update local vars and continue
        userDataStringNonNull = userDataString2;
        tokenNonNull = token2;
        setState(() {
          _userData = jsonDecode(userDataStringNonNull);
          _token = tokenNonNull;
        });
      } else {
        // User did not log in (cancelled) -> show message
        setState(() {
          _errorMessage = 'Please log in to view your cart';
          _isLoading = false;
        });
        return;
      }
    } else {
      userDataStringNonNull = userDataString;
      tokenNonNull = token;
      setState(() {
        _userData = jsonDecode(userDataStringNonNull);
        _token = tokenNonNull;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('https://fakestoreapi.com/carts/user/${_userData!['id']}'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final cartData = jsonDecode(response.body);
        if (cartData.isNotEmpty) {
          // Assuming the first cart for the user
          final products = cartData[0]['products'] as List<dynamic>;
          double total = 0.0;

          // Fetch product details for each item in the cart
          final List<dynamic> enrichedProducts = [];
          for (var product in products) {
            final productResponse = await http.get(
              Uri.parse('https://fakestoreapi.com/products/${product['productId']}'),
              headers: {'Authorization': 'Bearer $_token'},
            );
            if (productResponse.statusCode == 200) {
              final productData = jsonDecode(productResponse.body);
              enrichedProducts.add({
                'productId': product['productId'],
                'quantity': product['quantity'],
                'title': productData['title'],
                'price': productData['price'].toDouble(),
                'image': productData['image'],
              });
              total += productData['price'] * product['quantity'];
            }
          }

          setState(() {
            _cartItems = enrichedProducts;
            _totalPrice = total;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No items in your cart';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch cart data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: Colors.black54),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_cartItems != null ? _cartItems!.fold<int>(0, (s, i) => s + ((i['quantity'] is int) ? i['quantity'] as int : (i['quantity'] is num ? (i['quantity'] as num).toInt() : int.tryParse(i['quantity']?.toString() ?? '1') ?? 1))) : 0}',
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : (_cartItems == null || _cartItems!.isEmpty)
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/image3.png', width: 160, height: 120, fit: BoxFit.contain),
                            const SizedBox(height: 16),
                            const Text('Your cart is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Looks like you haven\'t added anything to your cart yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Continue Shopping'),
                            )
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _cartItems!.length,
                            itemBuilder: (context, index) {
                              final item = _cartItems![index];
                              // Safely parse price and quantity
                              final price = (item['price'] is num) ? (item['price'] as num).toDouble() : double.tryParse(item['price'].toString()) ?? 0.0;
                              final qty = (item['quantity'] is int)
                                  ? item['quantity'] as int
                                  : (item['quantity'] is num ? (item['quantity'] as num).toInt() : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1);

                              // identifier for Dismissible key
                              final id = item['id'] ?? item['productId'] ?? index;

                              return Dismissible(
                                key: ValueKey('cart_item_$id'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.delete_forever, color: Colors.white),
                                ),
                                onDismissed: (_) async {
                                  // find current index (list may have changed)
                                  final idx = _cartItems!.indexWhere((it) => (it['id'] ?? it['productId'] ?? it.hashCode) == id);
                                  if (idx >= 0) await _deleteItemAt(idx);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item removed from cart')));
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: 80,
                                            height: 80,
                                            child: (item['image'] != null && item['image'].toString().isNotEmpty)
                                                ? Image.network(
                                                    item['image'],
                                                    fit: BoxFit.contain,
                                                    width: 80,
                                                    height: 80,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        color: Colors.grey.shade100,
                                                        child: const Center(
                                                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (c, e, st) => Container(
                                                      color: Colors.grey.shade100,
                                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey.shade100,
                                                    child: const Icon(Icons.image, color: Colors.grey),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                                  const SizedBox(width: 12),
                                                  Text('x $qty', style: const TextStyle(color: Colors.grey)),
                                                  const Spacer(),
                                                  Text('\$${(price * qty).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  // small circular decrease
                                                  Tooltip(
                                                    message: 'Decrease quantity',
                                                    child: Material(
                                                      color: Colors.orange,
                                                      shape: const CircleBorder(),
                                                      child: InkWell(
                                                        customBorder: const CircleBorder(),
                                                        onTap: () => _decreaseQtyAt(index),
                                                        child: const SizedBox(width: 32, height: 32, child: Icon(Icons.remove, color: Colors.white, size: 16)),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                                    child: Text('$qty', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // small circular increase
                                                  Tooltip(
                                                    message: 'Increase quantity',
                                                    child: Material(
                                                      color: Colors.green,
                                                      shape: const CircleBorder(),
                                                      child: InkWell(
                                                        customBorder: const CircleBorder(),
                                                        onTap: () => _increaseQtyAt(index),
                                                        child: const SizedBox(width: 32, height: 32, child: Icon(Icons.add, color: Colors.white, size: 16)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5)]),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal', style: TextStyle(fontSize: 16)),
                                  Text('\$${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Shipping', style: TextStyle(fontSize: 16)),
                                  Text('\$5.00', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('\$${(_totalPrice + 5.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Continue Shopping'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage()));
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                      child: const Text('Checkout'),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}