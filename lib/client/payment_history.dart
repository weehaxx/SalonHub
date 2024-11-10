import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentHistory extends StatefulWidget {
  const PaymentHistory({super.key});

  @override
  State<PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // Function to fetch the payment history for the current user
  Stream<QuerySnapshot> _fetchPaymentHistory() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user?.uid)
        .collection('payment_history')
        .orderBy('paymentDate',
            descending: true) // Order by date (newest first)
        .snapshots();
  }

  // Function to fetch the salon name based on salonId
  Future<String> _fetchSalonName(String salonId) async {
    try {
      DocumentSnapshot salonDoc = await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .get();

      if (salonDoc.exists) {
        return salonDoc['salon_name'] ?? 'Unknown Salon';
      }
    } catch (e) {
      print('Error fetching salon name: $e');
    }
    return 'Unknown Salon';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment History',
          style: GoogleFonts.abel(color: Colors.white),
        ),
        backgroundColor: const Color(0xff355E3B), // Custom green color
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchPaymentHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No payment history found.',
                style: GoogleFonts.abel(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final payments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final paymentDoc = payments[index];
              final payment = paymentDoc.data() as Map<String, dynamic>;

              // Convert the Firestore timestamp to a readable date
              DateTime paymentDate =
                  (payment['paymentDate'] as Timestamp).toDate();

              return FutureBuilder<String>(
                future: _fetchSalonName(payment['salonId']),
                builder: (context, salonSnapshot) {
                  if (salonSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final salonName = salonSnapshot.data ?? 'Unknown Salon';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Payment to $salonName',
                              style: GoogleFonts.abel(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Reference Number: ${payment['reference_number'] ?? 'N/A'}',
                            style: GoogleFonts.abel(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Payment Date: ${paymentDate.toString()}',
                            style: GoogleFonts.abel(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                _showReceiptImage(payment['receipt_url'] ?? '');
                              },
                              child: Text(
                                'See Receipt',
                                style: GoogleFonts.abel(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Function to show the receipt image in full screen
  void _showReceiptImage(String receiptUrl) {
    if (receiptUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipt available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // Close the full-screen image
            },
            child: Center(
              child: Image.network(
                receiptUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Failed to load receipt'));
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
