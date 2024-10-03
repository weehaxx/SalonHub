import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PaymentMethodForm extends StatefulWidget {
  const PaymentMethodForm({super.key});

  @override
  PaymentMethodFormState createState() =>
      PaymentMethodFormState(); // Public class name
}

class PaymentMethodFormState extends State<PaymentMethodForm> {
  String? _selectedPaymentMethod;
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  // State for QR Code Image Picker
  File? _selectedQrCodeImage;
  final ImagePicker _imagePicker = ImagePicker();

  // List of available payment methods
  final List<String> _paymentMethods = ['Gcash', 'Paymaya', 'Bank Transfer'];

  // Getter methods for parent widget to access form data
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  String? get contactInfo => _selectedPaymentMethod == 'Bank Transfer'
      ? _accountNumberController.text
      : _phoneNumberController.text;
  File? get selectedQrCodeImage => _selectedQrCodeImage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xff355E3B),
            ),
          ),
          const SizedBox(height: 20),
          _buildPaymentMethodSelector(),
          if (_selectedPaymentMethod == 'Gcash' ||
              _selectedPaymentMethod == 'Paymaya')
            _buildTextField('Phone Number', _phoneNumberController, false),
          if (_selectedPaymentMethod == 'Bank Transfer')
            _buildTextField('Account Number', _accountNumberController, true),
          _buildQrCodeUploader(),
        ],
      ),
    );
  }

  // Widget to build a dropdown for payment method selection
  Widget _buildPaymentMethodSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
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
          labelStyle: const TextStyle(color: Color(0xff355E3B)),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff355E3B), width: 2),
          ),
        ),
      ),
    );
  }

  // Widget to build a text field
  Widget _buildTextField(
      String label, TextEditingController controller, bool isAccount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Color(0xff355E3B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xff355E3B)),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff355E3B), width: 2),
          ),
        ),
        keyboardType: isAccount ? TextInputType.number : TextInputType.phone,
      ),
    );
  }

  // Widget to build the QR code uploader
  Widget _buildQrCodeUploader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload QR Code (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff355E3B),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickQrCode,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xff355E3B),
                  width: 2,
                ),
              ),
              child: _selectedQrCodeImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedQrCodeImage!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.qr_code_2,
                        color: Color(0xff355E3B),
                        size: 50,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Pick a QR code image from the gallery
  Future<void> _pickQrCode() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedQrCodeImage = File(image.path);
      });
    }
  }
}
