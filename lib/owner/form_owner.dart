import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:salon_hub/owner/dashboard_owner.dart';
import 'package:salon_hub/owner/formComponents/employees_form.dart';
import 'package:salon_hub/owner/formComponents/payment_method.dart';
import 'package:salon_hub/owner/formComponents/image_picker_widget.dart';
import 'package:salon_hub/owner/formComponents/navigation_buttons.dart';
import 'package:salon_hub/owner/formComponents/salon_information.dart';
import 'package:salon_hub/owner/formComponents/services_form.dart';

class FormOwner extends StatefulWidget {
  const FormOwner({super.key});

  @override
  State<FormOwner> createState() => _FormOwnerState();
}

class _FormOwnerState extends State<FormOwner> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // GlobalKey to access the state of the PaymentMethodForm
  final GlobalKey<PaymentMethodFormState> _paymentMethodFormKey = GlobalKey();

  // State variables for all form components
  final List<Map<String, String>> _services = [];
  final List<Map<String, String>> _employees = [];

  // Controllers for Salon Information Form
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _salonOwnerController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _openTimeController = TextEditingController();
  final TextEditingController _closeTimeController = TextEditingController();

  // State for Image Picker
  File? _selectedImage;

  // Latitude and Longitude captured from SalonInformationForm
  double? _latitude;
  double? _longitude;

  // FirebaseAuth to get current user
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ImagePickerWidget(
                    key: UniqueKey(),
                    selectedImage: _selectedImage,
                    onImageSelected: (image) {
                      setState(() {
                        _selectedImage = image;
                      });
                    },
                  ),
                  SalonInformationForm(
                    key: UniqueKey(),
                    salonNameController: _salonNameController,
                    salonOwnerController: _salonOwnerController,
                    addressController: _addressController,
                    openTimeController: _openTimeController,
                    closeTimeController: _closeTimeController,
                    // Capture latitude and longitude here
                    onLocationSelected: (latitude, longitude) {
                      setState(() {
                        _latitude = latitude;
                        _longitude = longitude;
                      });
                    },
                  ),
                  ServicesForm(
                    key: UniqueKey(),
                    services: _services,
                  ),
                  EmployeesForm(
                    key: UniqueKey(),
                    employees: _employees,
                  ),
                  PaymentMethodForm(
                    key: _paymentMethodFormKey,
                  ),
                ],
              ),
            ),
            NavigationButtons(
              currentStep: _currentStep,
              onNext: _currentStep < 4 ? _nextStep : _submitForm,
              onPrevious: _previousStep,
              onSubmit: _currentStep == 4 ? _submitForm : () {},
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep < 4) {
      setState(() {
        _currentStep += 1;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User is not logged in. Please log in first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentMethodFormState = _paymentMethodFormKey.currentState;

    String? selectedPaymentMethod =
        paymentMethodFormState?.selectedPaymentMethod;
    String? contactInfo = paymentMethodFormState?.contactInfo;
    File? qrCodeImage = paymentMethodFormState?.selectedQrCodeImage;

    // Check if all required fields are filled
    if (_salonNameController.text.isEmpty ||
        _salonOwnerController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _openTimeController.text.isEmpty ||
        _closeTimeController.text.isEmpty ||
        _selectedImage == null ||
        selectedPaymentMethod == null ||
        contactInfo == null ||
        _latitude == null ||
        _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select an image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Upload image to Firebase Storage
      String imageUrl = await _uploadImage(_selectedImage!);

      // Upload QR code image to Firebase Storage (if exists)
      String? qrCodeUrl;
      if (qrCodeImage != null) {
        qrCodeUrl = await _uploadImage(qrCodeImage);
      }

      // Prepare salon data
      Map<String, dynamic> salonData = {
        'salon_name': _salonNameController.text
            .trim(), // Trim text to avoid leading/trailing spaces
        'owner_name': _salonOwnerController.text.trim(),
        'address': _addressController.text.trim(),
        'open_time': _openTimeController.text.trim(),
        'close_time': _closeTimeController.text.trim(),
        'image_url': imageUrl,
        'latitude': _latitude,
        'longitude': _longitude,
        'owner_uid': currentUser!.uid,
        'status': 'Open', // Add the default status here
      };

      // Prepare payment data
      Map<String, dynamic> paymentData = {
        'payment_method': selectedPaymentMethod,
        'contact_info': contactInfo,
        'qr_code_url': qrCodeUrl,
      };

      // Save the salon data to Firestore
      DocumentReference salonRef =
          FirebaseFirestore.instance.collection('salon').doc(currentUser!.uid);
      await salonRef.set(salonData);

      // Save payment method data
      await salonRef.collection('payment_methods').add(paymentData);

      // Save services
      for (var service in _services) {
        await salonRef.collection('services').add(service);
      }

      // Save employees
      for (var employee in _employees) {
        await salonRef.collection('stylists').add(employee);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Salon information and payment method submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _clearForm();

      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardOwner(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'salon_images/${currentUser!.uid}/${DateTime.now().toIso8601String()}.png');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  void _clearForm() {
    _salonNameController.clear();
    _salonOwnerController.clear();
    _addressController.clear();
    _openTimeController.clear();
    _closeTimeController.clear();
    _services.clear();
    _employees.clear();
    _selectedImage = null;
    _pageController.jumpToPage(0);
    setState(() {
      _currentStep = 0;
    });
  }
}
