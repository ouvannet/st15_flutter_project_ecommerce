import 'package:flutter/material.dart';
import 'package:flutter2/view/detailPage.dart';
import 'package:flutter2/view/auth/login.dart';
import 'package:flutter2/view/user/profile_page.dart';
import 'package:flutter2/view/user/cart_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter2/view/category/category_item.dart';
import 'package:flutter2/view/products/offer_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter2/model/product.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0;
  List<Product> _specialOffers = [];
  bool _isLoadingOffers = true;

  void _onItemTapped(int index) {
    // If profile icon tapped (index 3) handle login/profile navigation
    if (index == 3) {
      _handleProfileTap();
      return;
    }

    // If cart icon tapped (index 2) navigate to CartPage
    if (index == 2) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleProfileTap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        // User is logged in -> go to profile page
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
      } else {
        // Not logged in -> go to login page
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      }
    } catch (e) {
      // If SharedPreferences fails for some reason, fallback to login page
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('local_cart');
      final List<dynamic> cart = cartString != null ? jsonDecode(cartString) : [];

      // find product by id
      final idx = cart.indexWhere((p) => p['id'] == product.id);
      if (idx >= 0) {
        // increment quantity
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to local cart')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error storing cart: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSpecialOffers();
  }

  Future<void> fetchSpecialOffers() async {
    try {
      final response = await http.get(Uri.parse('https://fakestoreapi.com/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _specialOffers = data.map((json) => Product.fromJson(json)).toList();
          _isLoadingOffers = false;
        });
        print(jsonEncode(data)); // Log offers in JSON format for easier viewing
      } else {
        setState(() {
          _isLoadingOffers = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingOffers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 5.0,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/profile3.png',
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mike',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200, width: 2),
                        ),
                      ),
                      child: ListTile(
                        title: Row(
                          children: const [
                            Icon(Icons.favorite_border, color: Colors.black),
                            SizedBox(width: 40),
                            Text(
                              'Favorite',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200, width: 2),
                        ),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Icon(Icons.settings_outlined, color: Colors.black),
                            SizedBox(width: 40),
                            Text(
                              'Setting',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200, width: 2),
                        ),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Icon(Icons.logout_outlined, color: Colors.black),
                            SizedBox(width: 40),
                            Text(
                              'Logout',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFFFF),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                GestureDetector(
                  // onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage())),
                  // No product to pass here, so navigation is disabled. Uncomment and update if you want to show a default product.
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/slide1.png', width: screenWidth * 0.98, height: 200, fit: BoxFit.cover),
                  ),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shop By Categories',
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          CategoryItem(
                            label: 'Vegetables',
                            iconAsset: 'assets/category/vegetables.png',
                            onTap: () {
                              print('Vegetables tapped!');
                            },
                          ),
                          SizedBox(width: 16),
                          CategoryItem(
                            label: 'Fast Food',
                            iconAsset: 'assets/category/fast_food.png',
                            onTap: () {
                              print('Fast Food tapped!');
                            },
                          ),
                          SizedBox(width: 16),
                          CategoryItem(
                            label: 'Foods',
                            iconAsset: 'assets/category/foods.png',
                            onTap: () {
                              print('Foods tapped!');
                            },
                          ),
                          SizedBox(width: 16),
                          CategoryItem(
                            label: 'Drinks',
                            iconAsset: 'assets/category/drinks.png',
                            onTap: () {
                              print('Drinks tapped!');
                            },
                          ),
                          SizedBox(width: 16),
                          CategoryItem(
                            label: 'Fruits',
                            iconAsset: 'assets/category/fruits.png',
                            onTap: () {
                              print('Fruits!');
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        print('See All tapped!');
                      },
                      child: Text('See All'),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Special Offers',
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _isLoadingOffers
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                )
                              ]
                            : _specialOffers.map((product) {
                                return OfferCard(
                                  imageAsset: product.image,
                                  title: product.title,
                                  price: product.price,
                                  rating: product.rating.round(),
                                  onCardPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(product: product)));
                                  },
                                  onFavoritePressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(product: product)));
                                  },
                                  onCartPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final token = prefs.getString('auth_token');
                                    if (token == null || token.isEmpty) {
                                      if (!mounted) return;
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                                    } else {
                                      await _addToCart(product);
                                    }
                                  },
                                );
                              }).toList(),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Products',
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _isLoadingOffers
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                )
                              ]
                            : _specialOffers.map((product) {
                                return OfferCard(
                                  imageAsset: product.image,
                                  title: product.title,
                                  price: product.price,
                                  rating: product.rating.round(),
                                  onCardPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(product: product)));
                                  },
                                  onFavoritePressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(product: product)));
                                  },
                                  onCartPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final token = prefs.getString('auth_token');
                                    if (token == null || token.isEmpty) {
                                      if (!mounted) return;
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                                    } else {
                                      await _addToCart(product);
                                    }
                                  },
                                );
                              }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Grid',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}