import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter2/view/products/offer_card.dart';
import 'package:flutter2/model/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter2/view/auth/login.dart';
class DetailPage extends StatelessWidget {
  final Product product;
  const DetailPage({super.key, required this.product});

  Future<void> _addToCart(BuildContext context, Product product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('local_cart');
      final List<dynamic> cart = cartString != null ? jsonDecode(cartString) : [];

      final idx = cart.indexWhere((p) => p['id'] == product.id);
      if (idx >= 0) {
        final existing = Map<String, dynamic>.from(cart[idx]);
        existing['quantity'] = (existing['quantity'] ?? 1) + 1;
        cart[idx] = existing;
      } else {
        cart.add({
          'id': product.id,
          'title': product.title,
          'price': product.price,
          'description': product.description,
          'category': product.category,
          'image': product.image,
          'quantity': 1,
        });
      }

      await prefs.setString('local_cart', jsonEncode(cart));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to local cart')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error storing cart: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFDE296),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back_outlined, color: Colors.black,),
            onPressed: (){
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          'Detail',
          style: TextStyle( 
            fontWeight: FontWeight.bold,
            fontSize: 16
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black,),
            onPressed: (){},
          ),
        ],
      ),
      body:SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child:Padding(
          padding: const EdgeInsets.all(0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  child: product.image.startsWith('http')
                      ? Image.network(product.image, width: screenWidth * 1, height: 300, fit: BoxFit.contain)
                      : Image.asset(product.image, width: screenWidth * 1, height: 300, fit: BoxFit.contain),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color:Colors.grey.shade400, width: 1),
                      ),
                    ),
                    child:Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child:Column(
                        children: [
                          Row(
                            children: [
                              Row( // Row for stars and rating
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 250,
                                          child: Text(
                                            product.title,
                                            style: TextStyle(
                                              fontSize: 23,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.left,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: List.generate(5, (index) {
                                                return Icon(
                                                  Icons.star_border,
                                                  color: index < product.rating.round() ? Colors.amber : Colors.grey.shade400,
                                                  size: 16,
                                                );
                                              }),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('(${product.rating.toStringAsFixed(1)})', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(), // Pushes the heart to the end
                              const Icon(
                                Icons.favorite_border, // Correct icon name
                                color: Colors.grey,
                                size: 24,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Row( // Row for stars and rating
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "\$ ${product.price}" ,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(), // Pushes the heart to the end
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _addToCart(context, product),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Add To Cart'),
                                  ),
                                  SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Buy Now'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child:Container(
                    alignment: Alignment.centerLeft,
                    child:Column(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 0),
                            child: Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            product.description,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        
                      ],
                    )
                  )
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child:Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Related Products',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              print('See All tapped!');
                            },
                            child: Text('See All'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      FutureBuilder<http.Response>(
                        future: http.get(Uri.parse('https://fakestoreapi.com/products')),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.statusCode != 200) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Failed to load related products'),
                            );
                          } else {
                            final List<dynamic> data = jsonDecode(snapshot.data!.body);
                            final List<Product> products = data.map((json) => Product.fromJson(json)).toList();
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: products.map((product) {
                                  return OfferCard(
                                    imageAsset: product.image,
                                    title: product.title,
                                    price: product.price,
                                    rating: product.rating.round(),
                                    onCartPressed: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      final token = prefs.getString('auth_token');
                                      if (token == null || token.isEmpty) {
                                        if (!Navigator.of(context).mounted) return;
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                                      } else {
                                        await _addToCart(context, product);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ),
      ),
    );
  }
}