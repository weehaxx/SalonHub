import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For Clipboard API
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'dart:io'; // For handling file

class DownpaymentClient extends StatefulWidget {
  final String salonId;
  final double totalPrice;
  final String appointmentId;

  const DownpaymentClient({
    super.key,
    required this.salonId,
    required this.totalPrice,
    required this.appointmentId,
  });

  @override
  State<DownpaymentClient> createState() => _DownpaymentClientState();
}

class _DownpaymentClientState extends State<DownpaymentClient> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _paymentMethods = [];
  late double downPaymentAmount;
  File? _receiptImage;
  final TextEditingController _referenceController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    downPaymentAmount = widget.totalPrice * 0.5;
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      QuerySnapshot paymentMethodsSnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('payment_methods')
          .get();

      if (paymentMethodsSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> methods =
            paymentMethodsSnapshot.docs.map((doc) {
          final data =
              doc.data() as Map<String, dynamic>?; // Ensure null safety
          return {
            'payment_method':
                data?['payment_method']?.toString() ?? 'Unknown Method',
            'contact_info':
                data?['contact_info']?.toString() ?? 'No Contact Info',
            'qr_code_url':
                data?['qr_code_url']?.toString() ?? '', // Empty if null
          };
        }).toList();

        setState(() {
          _paymentMethods = methods;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching payment methods: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPayment() async {
    if (_receiptImage != null && _referenceController.text.isNotEmpty) {
      setState(() {
        _isUploading = true; // Set uploading state to true
      });

      try {
        // Upload the receipt image to Firebase Storage
        String fileName = 'receipts/${widget.appointmentId}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putFile(_receiptImage!);

        TaskSnapshot storageSnapshot = await uploadTask;
        String downloadUrl = await storageSnapshot.ref.getDownloadURL();

        // Save the download URL and reference number to Firestore
        final appointmentRef = FirebaseFirestore.instance
            .collection('salon')
            .doc(widget.salonId)
            .collection('appointments')
            .doc(widget.appointmentId);

        // Check if the appointment document exists
        final snapshot = await appointmentRef.get();
        if (!snapshot.exists) {
          throw 'Appointment not found';
        }

        await appointmentRef.update({
          'receipt_url': downloadUrl, // Store the download URL
          'reference_number': _referenceController.text,
          'isPaid': true, // Mark as paid
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment submitted successfully!')),
        );
        Navigator.pop(context); // Close the modal
      } catch (e) {
        print('Error submitting payment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit payment: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false; // Reset uploading state
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please upload a receipt and enter a reference number.')),
      );
    }
  }

  // Show the popup for uploading receipt and entering reference number
  void _showPaymentPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upload Receipt & Reference',
                  style: GoogleFonts.abel(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff355E3B),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: 'Reference Number',
                    labelStyle: GoogleFonts.abel(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _pickReceiptImage,
                  icon: const Icon(Icons.upload),
                  label: Text(
                    'Upload Receipt',
                    style: GoogleFonts.abel(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                if (_receiptImage != null)
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 300, // Maximum height for the image
                      maxWidth: 300, // Maximum width for the image
                    ),
                    child: Image.file(
                      _receiptImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : _submitPayment, // Disable button if uploading
                  child: _isUploading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          'Submit Payment',
                          style: GoogleFonts.abel(color: Colors.white),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff355E3B), // Custom color
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          'Downpayment',
          style: GoogleFonts.abel(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xff355E3B),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentMethods.isEmpty
              ? const Center(
                  child: Text('No payment methods available'),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _paymentMethods.length,
                          itemBuilder: (context, index) {
                            final paymentMethod = _paymentMethods[index];
                            final String paymentMethodStr =
                                paymentMethod['payment_method'] ??
                                    'Unknown Method';
                            final String contactInfo =
                                paymentMethod['contact_info'] ??
                                    'No Contact Info';
                            final String qrCodeUrl =
                                paymentMethod['qr_code_url'] ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: Colors.grey.withOpacity(0.2),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    paymentMethodStr.toLowerCase() == 'gcash'
                                        ? Center(
                                            child: Image.asset(
                                              'assets/images/gcash.png',
                                              height: 40,
                                            ),
                                          )
                                        : Text(
                                            paymentMethodStr,
                                            style: GoogleFonts.abel(
                                              textStyle: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xff2E2E2E),
                                              ),
                                            ),
                                          ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Recipient #: $contactInfo',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.abel(
                                            textStyle: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy,
                                              color: Colors.grey),
                                          onPressed: () =>
                                              _copyToClipboard(contactInfo),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    if (qrCodeUrl.isNotEmpty)
                                      Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            qrCodeUrl,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Center(
                                                child: Text(
                                                    'Failed to load QR code'),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                    else
                                      const Center(
                                        child: Text(
                                          'No QR code available',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Total Price: Php ${widget.totalPrice.toStringAsFixed(2)}',
                                      style: GoogleFonts.abel(
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff2E2E2E),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Downpayment (50%): Php ${downPaymentAmount.toStringAsFixed(2)}',
                                      style: GoogleFonts.abel(
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff2E2E2E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton(
                          onPressed: _showPaymentPopup,
                          child: const Text('Pay',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff355E3B),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            textStyle: const TextStyle(fontSize: 16),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
    );
  }
}
