import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter2/view/homepage.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final token = prefs.getString('auth_token');

    setState(() {
      if (userDataString != null) {
        _userData = jsonDecode(userDataString);
      }
      _token = token;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate back to home page and clear navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_userData == null || _token == null)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 72, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No user data found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Return to Home'),
                        )
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      expandedHeight: 220,
                      pinned: true,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4CA1AF), Color(0xFFC4E0E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 44,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        child: CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.white,
                                          child: Text(
                                            (_userData!['firstName'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_userData!['firstName']} ${_userData!['lastName']}',
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _userData!['email'] ?? '',
                                              style: const TextStyle(color: Colors.white70),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _buildStat('Orders', '12'),
                                                const SizedBox(width: 12),
                                                _buildStat('Wishlist', '4'),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit profile not implemented')));
                                        },
                                        icon: const Icon(Icons.edit, color: Colors.white),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.person_outline, color: Colors.blue),
                                      title: Text('${_userData!['firstName']} ${_userData!['lastName']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text(_userData!['username'] ?? ''),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      leading: const Icon(Icons.email_outlined, color: Colors.orange),
                                      title: const Text('Email'),
                                      subtitle: Text(_userData!['email'] ?? ''),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      leading: const Icon(Icons.fingerprint, color: Colors.green),
                                      title: const Text('User ID'),
                                      subtitle: Text(_userData!['id'].toString()),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.shopping_bag_outlined, color: Colors.purple),
                                    title: const Text('My Orders'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('My Orders - not implemented'))),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: const Icon(Icons.location_on_outlined, color: Colors.redAccent),
                                    title: const Text('Addresses'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Addresses - not implemented'))),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: const Icon(Icons.payment_outlined, color: Colors.teal),
                                    title: const Text('Payment Methods'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Methods - not implemented'))),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: const Icon(Icons.logout, color: Colors.red),
                                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                                    onTap: _handleLogout,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
    );
  }

  // ...existing code...

  Widget _buildStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}