import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../complaintspage.dart';
import '../loginfile/loginpage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  String? _gender;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user?.phoneNumber == null) return;

    final doc = await _firestore.collection('users').doc(user!.phoneNumber).get();

    if (doc.exists) {
      _nameController.text = doc['name'] ?? "";
      _gender = doc['gender'];
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Account",
          style: TextStyle(
            color: Color(0xFFC62828),
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.mode_edit_outline_rounded, 
                      color: _isEditing ? Colors.grey : const Color(0xFFC62828)),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSectionCard(
                    title: "Personal Details",
                    child: Column(
                      children: [
                        _buildInfoField("Name", _nameController, Icons.person_outline_rounded, enabled: _isEditing),
                        const Divider(height: 30, color: Color(0xFFF5F5F5)),
                        _buildGenderDropdown(),
                        const Divider(height: 30, color: Color(0xFFF5F5F5)),
                        _buildStaticInfo("Phone", _auth.currentUser?.phoneNumber ?? "N/A", Icons.phone_android_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: "Support & Actions",
                    child: Column(
                      children: [
                        _buildMenuTile(
                          icon: Icons.assignment_late_outlined,
                          title: "My Complaints",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyComplaintsPage())),
                        ),
                        const Divider(height: 1, color: Color(0xFFF5F5F5)),
                        _buildMenuTile(
                          icon: Icons.mail_outline_rounded,
                          title: "Contact Support",
                          subtitle: "arkabeam@gmail.com",
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_isEditing)
                    _buildMetallicButton("Save Changes", const Color(0xFFC62828), _updateProfile),
                  const SizedBox(height: 15),
                  _buildMetallicButton("Log Out", Colors.grey[800]!, _logout),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC62828).withOpacity(0.2), width: 1),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFF5F6F8),
                  child: Icon(Icons.person_rounded, size: 50, color: Colors.grey[400]),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFC62828),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _nameController.text.isEmpty ? "User Name" : _nameController.text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50)),
          ),
          Text(
            _auth.currentUser?.phoneNumber ?? "",
            style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey[400], letterSpacing: 1.5)),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, IconData icon, {required bool enabled}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFC62828)),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              TextField(
                controller: controller,
                enabled: enabled,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none,
                  hintText: "Enter $label",
                  hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaticInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Row(
      children: [
        const Icon(Icons.people_outline_rounded, size: 20, color: Color(0xFFC62828)),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Gender", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _gender,
                  isDense: true,
                  disabledHint: Text(_gender ?? "Select Gender", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  items: ["Male", "Female", "Other"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: _isEditing ? (v) => setState(() => _gender = v) : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: const Color(0xFFC62828)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildMetallicButton(String label, Color color, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    await _firestore.collection('users').doc(user!.phoneNumber).update({
      "name": _nameController.text,
      "gender": _gender,
    });
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated")));
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
  }
}
