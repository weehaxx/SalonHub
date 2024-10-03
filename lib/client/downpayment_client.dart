import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DownpaymentClient extends StatefulWidget {
  const DownpaymentClient({super.key});

  @override
  State<DownpaymentClient> createState() => _DownpaymentClientState();
}

class _DownpaymentClientState extends State<DownpaymentClient> {
  String? _selectedPaymentMethod; // Track the selected payment method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Payment Method',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xff355E3B),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your payment method:',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildPaymentMethodTile('Credit Card', Icons.credit_card),
            _buildPaymentMethodTile('Debit Card', Icons.account_balance_wallet),
            _buildPaymentMethodTile('PayPal', Icons.account_balance),
            _buildPaymentMethodTile('Cash on Delivery', Icons.money),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _selectedPaymentMethod != null
              ? () {
                  _showConfirmationDialog(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff355E3B),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Text(
            'Proceed',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  // Build payment method tile
  Widget _buildPaymentMethodTile(String method, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff355E3B)),
      title: Text(
        method,
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
      trailing: Radio<String>(
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (String? value) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        activeColor: const Color(0xff355E3B),
      ),
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
    );
  }

  // Show confirmation dialog
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Payment Method'),
          content: Text(
            'You selected: $_selectedPaymentMethod.\nDo you want to proceed with this payment method?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Add further actions, such as navigating to a payment gateway
                _proceedWithPayment();
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  // Function to proceed with payment logic
  void _proceedWithPayment() {
    // Add your payment processing logic here
    // For now, it just shows a snackbar as a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Proceeding with $_selectedPaymentMethod',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}
