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

  // FirebaseAuth to get current user
  User? currentUser;

  @override
  void initState() {
    super.initState();
    // Fetch the current logged-in user
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
                    key: _paymentMethodFormKey, // Use GlobalKey here
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
    // Ensure the current user is available
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User is not logged in. Please log in first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Access the state of the PaymentMethodForm to retrieve the payment method info
    final paymentMethodFormState = _paymentMethodFormKey.currentState;

    String? selectedPaymentMethod =
        paymentMethodFormState?.selectedPaymentMethod;
    String? contactInfo = paymentMethodFormState?.contactInfo;
    File? qrCodeImage = paymentMethodFormState?.selectedQrCodeImage;

    // Check if required fields are filled
    if (_salonNameController.text.isEmpty ||
        _salonOwnerController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _openTimeController.text.isEmpty ||
        _closeTimeController.text.isEmpty ||
        _selectedImage == null ||
        selectedPaymentMethod == null ||
        contactInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select an image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Upload image to Firebase Storage and get the URL
      String imageUrl = await _uploadImage(_selectedImage!);

      // Upload QR code image to Firebase Storage (if exists) and get the URL
      String? qrCodeUrl;
      if (qrCodeImage != null) {
        qrCodeUrl = await _uploadImage(qrCodeImage);
      }

      // Prepare data to be sent to Firestore for the main salon document
      Map<String, dynamic> salonData = {
        'salon_name': _salonNameController.text,
        'owner_name': _salonOwnerController.text,
        'address': _addressController.text,
        'open_time': _openTimeController.text,
        'close_time': _closeTimeController.text,
        'image_url': imageUrl,
        'owner_uid': currentUser!.uid, // Associate with logged-in user
      };

      // Prepare payment method data
      Map<String, dynamic> paymentData = {
        'payment_method': selectedPaymentMethod,
        'contact_info': contactInfo,
        'qr_code_url': qrCodeUrl, // Set the QR code URL if exists
      };

      // Save the main salon document to Firestore with user ID as the document ID
      DocumentReference salonRef =
          FirebaseFirestore.instance.collection('salon').doc(currentUser!.uid);

      await salonRef.set(salonData);

      // Save payment method as a subcollection under the main salon document
      await salonRef.collection('payment_methods').add(paymentData);

      // Add the services subcollection
      for (var service in _services) {
        await salonRef.collection('services').add(service);
      }

      // Add the employees subcollection
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

      // Clear form after submission
      _clearForm();

      // Navigate to the Dashboard screen after success
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
