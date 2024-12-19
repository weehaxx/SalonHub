import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ChangePaymentMethodPage extends StatefulWidget {
  const ChangePaymentMethodPage({Key? key}) : super(key: key);

  @override
  State<ChangePaymentMethodPage> createState() =>
      _ChangePaymentMethodPageState();
}

class _ChangePaymentMethodPageState extends State<ChangePaymentMethodPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  final TextEditingController _contactInfoController = TextEditingController();
  File? _selectedQrCodeImage;
  final ImagePicker _imagePicker = ImagePicker();
  String? qrCodeUrl;

  bool isLoading = false;
  Map<String, dynamic>? currentPaymentMethod;
  final List<String> _paymentMethods = ['Gcash', 'Paymaya', 'Bank Transfer'];
  String? _selectedPaymentMethod;

  Future<void> fetchCurrentPaymentMethod() async {
    try {
      if (_user == null) {
        throw Exception('User not authenticated');
      }
      final salonDocRef =
          FirebaseFirestore.instance.collection('salon').doc(_user?.uid);
      final paymentMethodsCollectionRef =
          salonDocRef.collection('payment_methods');
      final querySnapshot = await paymentMethodsCollectionRef.get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          currentPaymentMethod = querySnapshot.docs.first.data();
          _selectedPaymentMethod = currentPaymentMethod?['payment_method'];
          _contactInfoController.text =
              currentPaymentMethod?['contact_info'] ?? '';
          qrCodeUrl = currentPaymentMethod?['qr_code_url'];
        });
      }
    } catch (e) {
      print('Error fetching current payment method: $e');
    }
  }

  Future<void> replacePaymentMethod() async {
    try {
      if (_user == null) {
        throw Exception('User not authenticated');
      }

      final salonDocRef =
          FirebaseFirestore.instance.collection('salon').doc(_user?.uid);
      final paymentMethodsCollectionRef =
          salonDocRef.collection('payment_methods');
      final querySnapshot = await paymentMethodsCollectionRef
          .where('payment_method', isEqualTo: _selectedPaymentMethod)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;

        Map<String, dynamic> data = {
          'payment_method': _selectedPaymentMethod ?? '',
          'contact_info': _contactInfoController.text,
        };

        if (_selectedQrCodeImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('qr_codes')
              .child(
                  '${_user?.uid}_${DateTime.now().millisecondsSinceEpoch}.png');
          final uploadTask = await storageRef.putFile(_selectedQrCodeImage!);
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          data['qr_code_url'] = downloadUrl;
        }

        await docRef.update(data);

        // Log the action
        await _logAction(
          actionType: 'Payment Method Changed',
          description:
              'Payment method changed to $_selectedPaymentMethod. Contact Info: ${_contactInfoController.text}.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method updated successfully!')),
        );

        await fetchCurrentPaymentMethod();
      } else {
        throw Exception('Payment method not found.');
      }
    } catch (e) {
      print('Error updating payment method: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating payment method.')),
      );
    }
  }

  Future<void> _logAction({
    required String actionType,
    required String description,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('logs')
          .add({
        'actionType': actionType,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging action: $e');
    }
  }

  Future<void> _pickQrCode() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedQrCodeImage = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCurrentPaymentMethod();
  }

  void _showUpdatePaymentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Payment Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  items: _paymentMethods.map((String method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Payment Method',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contactInfoController,
                  decoration: InputDecoration(
                    labelText: _selectedPaymentMethod == 'Bank Transfer'
                        ? 'Account Number'
                        : 'Contact Info',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickQrCode,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _selectedQrCodeImage != null
                        ? Image.file(
                            _selectedQrCodeImage!,
                            fit: BoxFit.cover,
                          )
                        : qrCodeUrl != null
                            ? Image.network(
                                qrCodeUrl!,
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Text('Tap to upload QR Code'),
                              ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  isLoading = true;
                });
                Navigator.of(context).pop();
                await replacePaymentMethod();
                setState(() {
                  isLoading = false;
                });
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Payment Method'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Payment Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  currentPaymentMethod != null
                      ? Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Method: ${currentPaymentMethod?['payment_method']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Contact Info: ${currentPaymentMethod?['contact_info']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                if (qrCodeUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      qrCodeUrl!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : const Text('No payment method available.'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showUpdatePaymentDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Update Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
