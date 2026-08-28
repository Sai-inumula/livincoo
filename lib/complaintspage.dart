import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyComplaintsPage extends StatelessWidget {
  const MyComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final String phone = user.phoneNumber ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Complaints"),
        backgroundColor: Colors.red[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Complaints')
                .where('customerId', isEqualTo: phone.toString())
                .orderBy('createdDate', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          /// 🔄 Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ Error
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          /// 📭 No Data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No complaints found"));
          }

          final complaints = snapshot.data!.docs;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final doc = complaints[index];
              final data = doc.data() as Map<String, dynamic>;

              final String complaintId = data['complaintId'].toString();
              final String issue = data['issue'] ?? "";
              final bool isResolved = data['isResolved'] ?? false;

              final Timestamp? createdTimestamp =
                  data['createdDate'] as Timestamp?;

              final DateTime? createdDate = createdTimestamp?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: Container(
                    width: 70,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isResolved ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Text(
                      textAlign: TextAlign.center,
                      complaintId.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  /// 🧾 Issue
                  title: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      issue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  /// 📅 Date
                  subtitle: Text(
                    createdDate != null
                        ? "${createdDate.day}/${createdDate.month}/${createdDate.year}"
                        : "",
                  ),

                  /// 🔄 Status
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isResolved ? Icons.check_circle : Icons.pending,
                        color: isResolved ? Colors.green : Colors.orange,
                      ),
                      Text(
                        isResolved ? "Resolved" : "Pending",
                        style: TextStyle(
                          fontSize: 12,
                          color: isResolved ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  /// 🔒 Tap Logic
                  onTap: () {
                    if (isResolved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Complaint already resolved"),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintChatPage(complaintId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ComplaintChatPage extends StatefulWidget {
  final String complaintId;

  const ComplaintChatPage({super.key, required this.complaintId});

  @override
  State<ComplaintChatPage> createState() => _ComplaintChatPageState();
}

class _ComplaintChatPageState extends State<ComplaintChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  bool isResolved = false;

  @override
  void initState() {
    super.initState();
    _checkResolvedStatus();
  }

  /// 🔒 Check if complaint resolved
  Future<void> _checkResolvedStatus() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('Complaints')
            .doc(widget.complaintId)
            .get();

    if (doc.exists) {
      setState(() {
        isResolved = doc['isResolved'] ?? false;
      });
    }
  }

  /// 📤 Send Message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (isResolved) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    final messageRef =
        FirebaseFirestore.instance
            .collection('Complaints')
            .doc(widget.complaintId)
            .collection('messages')
            .doc();

    await messageRef.set({
      "text": text,
      "sender": "customer",
      "createdAt": Timestamp.now(),
    });

    _scrollToBottom();
  }

  /// ⬇️ Auto scroll
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
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
    final messagesStream =
        FirebaseFirestore.instance
            .collection('Complaints')
            .doc(widget.complaintId)
            .collection('messages')
            .orderBy('createdAt')
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text("Complaint #${widget.complaintId}"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          /// 🔒 Resolved banner
          if (isResolved)
            Container(
              width: double.infinity,
              color: Colors.green,
              padding: const EdgeInsets.all(8),
              child: const Text(
                "This complaint is resolved. Chat is closed.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

          /// 💬 Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;

                    final text = data['text'] ?? '';
                    final sender = data['sender'] ?? '';

                    final isCustomer = sender == "customer";

                    return Align(
                      alignment:
                          isCustomer
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              isCustomer
                                  ? Colors.orange.shade200
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(text),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// 📤 Input box
          if (!isResolved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.orange),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
