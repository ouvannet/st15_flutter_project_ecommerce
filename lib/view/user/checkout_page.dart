import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter2/view/homepage.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<dynamic> _cartItems = [];
  double _subtotal = 0.0;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  // card fields (mock)
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  String _paymentMethod = 'cod';
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadLocalCart();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('local_cart');
    if (s != null) {
      final List<dynamic> cart = jsonDecode(s);
      double total = 0.0;
      for (var it in cart) {
        final price = (it['price'] is num) ? (it['price'] as num).toDouble() : double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
        final qty = (it['quantity'] is int) ? it['quantity'] as int : (it['quantity'] is num ? (it['quantity'] as num).toInt() : int.tryParse(it['quantity']?.toString() ?? '1') ?? 1);
        total += price * qty;
      }
      setState(() {
        _cartItems = cart;
        _subtotal = total;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      // validation failed
      return;
    }

    // If card payment selected, basic card validation
    if (_paymentMethod == 'card') {
      if (_cardNumberController.text.trim().length < 12) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid card number')));
        return;
      }
    }

    setState(() => _isPlacingOrder = true);

    // Simulate network / order creation delay
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_cart');

    setState(() {
      _isPlacingOrder = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully')));
    // Navigate to home and clear stack
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final shipping = 5.0;
    final total = _subtotal + shipping;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final shipping = 5.0;
        final total = _subtotal + shipping;

        Widget formSection = Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shipping Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter address' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city)),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter city' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 140,
                            child: TextFormField(
                              controller: _zipController,
                              decoration: const InputDecoration(labelText: 'ZIP', prefixIcon: Icon(Icons.mail)),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'ZIP' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'cod',
                      groupValue: _paymentMethod,
                      title: const Text('Cash on Delivery'),
                      onChanged: (v) => setState(() => _paymentMethod = v ?? 'cod'),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      value: 'card',
                      groupValue: _paymentMethod,
                      title: const Text('Credit / Debit Card'),
                      onChanged: (v) => setState(() => _paymentMethod = v ?? 'card'),
                    ),
                    if (_paymentMethod == 'card')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _cardNumberController,
                              decoration: const InputDecoration(labelText: 'Card number', prefixIcon: Icon(Icons.credit_card)),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: TextFormField(controller: _cardExpiryController, decoration: const InputDecoration(labelText: 'MM/YY'))),
                                const SizedBox(width: 12),
                                SizedBox(width: 120, child: TextFormField(controller: _cardCvvController, decoration: const InputDecoration(labelText: 'CVV'))),
                              ],
                            )
                          ],
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isWide)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(padding: const EdgeInsets.all(12.0), child: _buildSummaryContent(shipping, total)),
                ),
              const SizedBox(height: 12),
              if (!isWide)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: _isPlacingOrder ? const CircularProgressIndicator(color: Colors.white) : const Text('Place Order', style: TextStyle(fontSize: 16)),
                  ),
                ),
            ],
          ),
        );

        Widget summarySection = Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(padding: const EdgeInsets.all(16.0), child: _buildSummaryContent(shipping, total)),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: formSection),
                    const SizedBox(width: 20),
                    SizedBox(width: 360, child: Column(children: [summarySection, const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isPlacingOrder ? null : _placeOrder, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: _isPlacingOrder ? const CircularProgressIndicator(color: Colors.white) : const Padding(padding: EdgeInsets.symmetric(vertical: 14.0), child: Text('Place Order'))))])),
                  ],
                )
              : formSection,
        );
      }),
    );
  }

  Widget _buildSummaryContent(double shipping, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView(
            shrinkWrap: true,
            children: _cartItems.map((it) {
              final price = (it['price'] is num) ? (it['price'] as num).toDouble() : double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
              final qty = (it['quantity'] is int) ? it['quantity'] as int : (it['quantity'] is num ? (it['quantity'] as num).toInt() : int.tryParse(it['quantity']?.toString() ?? '1') ?? 1);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(children: [Expanded(child: Text(it['title'] ?? 'Item', maxLines: 1, overflow: TextOverflow.ellipsis)), Text('x$qty'), const SizedBox(width: 12), Text('\$${(price * qty).toStringAsFixed(2)}')]),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('\$${_subtotal.toStringAsFixed(2)}')]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Shipping'), Text('\$${shipping.toStringAsFixed(2)}')]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))]),
      ],
    );
  }
}
