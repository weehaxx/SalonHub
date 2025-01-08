import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingClient extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> stylists;
  final String salonId;

  const BookingClient({
    super.key,
    required this.services,
    required this.stylists,
    required this.salonId,
  });

  @override
  State<BookingClient> createState() => _BookingClientState();
}

class _BookingClientState extends State<BookingClient> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime; // Initialize with null to represent unset time
  String? _selectedStylist;
  String? _userName;
  String selectedCategory = 'All'; // Track the selected category
  final List<Map<String, dynamic>> _selectedServices =
      []; // Track selected services
  double _totalPrice = 0.0; // Track the total price of selected services

  final ScrollController _scrollController =
      ScrollController(); // Add ScrollController

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the controller when done
    super.dispose();
  }

  // Function to fetch the current user's name
  Future<void> _fetchCurrentUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['name'] ?? 'Unknown User'; // Fetch user's name
          });
        }
      } catch (e) {
        print('Error fetching user name: $e');
        setState(() {
          _userName = 'Unknown User';
        });
      }
    }
  }

  // Filter services based on selected category
  List<Map<String, dynamic>> _filterServices() {
    if (selectedCategory == 'All') {
      return widget.services;
    }
    return widget.services
        .where((service) => service['category'] == selectedCategory)
        .toList();
  }

  // Filter stylists based on selected category
  List<Map<String, dynamic>> _filterStylists() {
    if (selectedCategory == 'All') {
      return widget.stylists;
    }

    // Filter stylists based on selected category, handling both String and List cases
    return widget.stylists.where((stylist) {
      var categoriesField = stylist['categories'];

      // If categories are stored as a comma-separated string, split into a list
      if (categoriesField is String) {
        categoriesField =
            categoriesField.split(',').map((e) => e.trim()).toList();
      }

      // Ensure categoriesField is treated as a List
      if (categoriesField is List<dynamic>) {
        List<String> categories =
            categoriesField.map((item) => item.toString()).toList();

        // Check if the stylist's categories include the selected category
        return categories
            .map(
                (e) => e.trim().toLowerCase()) // Normalize the category strings
            .contains(selectedCategory.toLowerCase());
      }

      // Default to excluding stylists with no valid categories
      return false;
    }).toList();
  }

  // Update the total price of selected services
  void _updateTotalPrice() {
    _totalPrice = 0.0;
    for (var service in _selectedServices) {
      // Parse price as double, defaulting to 0.0 if parsing fails
      double price = double.tryParse(service['price'].toString()) ?? 0.0;
      _totalPrice += price;
    }
  }

  // Function to validate if all required fields are selected
  bool _validateSelections() {
    if (_selectedServices.isEmpty) {
      _showErrorDialog("Please select at least one service.");
      return false;
    }
    if (_selectedServices.length > 1 && _selectedStylist != 'Any stylist') {
      _selectedStylist = 'Any stylist'; // Automatically set to 'Any stylist'
    }
    if (_selectedStylist == null) {
      _showErrorDialog("Please select a stylist.");
      return false;
    }
    if (_selectedTime == null) {
      _showErrorDialog("Please select a time.");
      return false;
    }
    return true;
  }

  // Function to show error messages
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredServices = _filterServices();
    List<Map<String, dynamic>> filteredStylists = _filterStylists();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff355E3B),
        centerTitle: true,
        title: Text(
          'Booking',
          style: GoogleFonts.abel(
            textStyle: const TextStyle(color: Colors.white),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom: 80), // Ensure enough space for the button
              child: Column(
                children: [
                  // Category buttons section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _scrollController,
                      child: Row(
                        children: [
                          _buildCategoryButton('All'),
                          const SizedBox(width: 10),
                          _buildCategoryButton('Hair'),
                          const SizedBox(width: 10),
                          _buildCategoryButton('Nail'),
                          const SizedBox(width: 10),
                          _buildCategoryButton('Spa'),
                          const SizedBox(width: 10),
                          _buildCategoryButton('Others'),
                          const SizedBox(width: 10),
                          // Add more categories if needed
                        ],
                      ),
                    ),
                  ),
                  // Select Services section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xff355E3B), width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        maxHeight:
                            300, // Increased max height for better visibility
                        minHeight:
                            150, // Set a minimum height to prevent collapse
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Services',
                            style: GoogleFonts.abel(
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (filteredServices.isEmpty)
                            Expanded(
                              child: Center(
                                child: Text(
                                  'No available services for this category.',
                                  style: GoogleFonts.abel(
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility:
                                    true, // Makes the scrollbar thumb visible
                                thickness:
                                    4, // Adjust the thickness of the scrollbar
                                radius: const Radius.circular(
                                    10), // Radius for rounded scrollbar
                                child: ListView(
                                  controller: _scrollController,
                                  children: filteredServices.map((service) {
                                    return CheckboxListTile(
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${service['name']} - Php ${service['price']}",
                                            style: GoogleFonts.abel(
                                              textStyle:
                                                  const TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          Text(
                                            "Main Category: ${service['main_category'] ?? 'N/A'}",
                                            style: GoogleFonts.abel(
                                              textStyle: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      value:
                                          _selectedServices.contains(service),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedServices.add(service);
                                          } else {
                                            _selectedServices.remove(service);
                                          }
                                          _updateTotalPrice(); // Update total price when services are changed
                                          // Set stylist to "Any stylist" if more than one service is selected
                                          if (_selectedServices.length > 1) {
                                            _selectedStylist = 'Any stylist';
                                          } else {
                                            _selectedStylist = null;
                                          }
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      activeColor: const Color(0xff355E3B),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Note for multiple services
                  if (_selectedServices.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 10, left: 16.0, right: 16.0),
                      child: Text(
                        'Note: Stylist set to "Any stylist" since multiple services are selected.',
                        style: GoogleFonts.abel(
                          textStyle:
                              const TextStyle(fontSize: 14, color: Colors.red),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Select Stylist section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xff355E3B), width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedStylist,
                        hint: Text(
                          'Select Stylist',
                          style: GoogleFonts.abel(
                              textStyle: const TextStyle(fontSize: 20)),
                        ),
                        isExpanded: true,
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: _selectedServices.length > 1
                            ? null // Disable dropdown if more than one service is selected
                            : (String? newValue) {
                                setState(() {
                                  _selectedStylist = newValue;
                                });
                              },
                        items: [
                          if (_selectedServices.length > 1)
                            DropdownMenuItem<String>(
                              value: 'Any stylist',
                              child: Text('Any stylist',
                                  style: GoogleFonts.abel()),
                            ),
                          ...filteredStylists.map<DropdownMenuItem<String>>(
                              (Map<String, dynamic> value) {
                            return DropdownMenuItem<String>(
                              value: value['name'],
                              child: Text(
                                value['name'],
                                style: GoogleFonts.abel(
                                    textStyle: const TextStyle(fontSize: 20)),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  // Calendar section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                            color: const Color(0xff355E3B), width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TableCalendar(
                          firstDay: DateTime.now(),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: _focusedDay,
                          calendarFormat: CalendarFormat.twoWeeks,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (!isSameDay(_selectedDay, selectedDay)) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: GoogleFonts.abel(
                                textStyle: const TextStyle(fontSize: 25)),
                          ),
                          calendarStyle: CalendarStyle(
                            defaultTextStyle: GoogleFonts.abel(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Select Time button
                  ElevatedButton(
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ??
                            const TimeOfDay(
                                hour: 0, minute: 0), // Set initial to "00:00"
                      );
                      setState(() {
                        _selectedTime = pickedTime ??
                            const TimeOfDay(
                                hour: 0, minute: 0); // Set "00:00" if null
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      backgroundColor: const Color(0xffFFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                            color: Color(0xff355E3B), width: 2),
                      ),
                    ),
                    child: Text(
                      'Select Time: ${_selectedTime != null ? _selectedTime!.format(context) : "00:00"}', // Display "00:00" if not set
                      style: GoogleFonts.abel(
                        textStyle: const TextStyle(
                            fontSize: 18, color: Color(0xff000000)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Confirm button positioned at the bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                if (_validateSelections()) {
                  _showConfirmationDialog(context); // Show confirmation dialog
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                backgroundColor: const Color(0xff355E3B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 6, // Adds a floating effect to the button
              ),
              child: Text(
                'CONFIRM',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to show the confirmation dialog
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Your Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Date: ${_selectedDay != null ? _selectedDay.toString().split(' ')[0] : 'None'}',
                style: GoogleFonts.abel(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected Services: ${_selectedServices.isNotEmpty ? _selectedServices.map((s) => s['name']).join(', ') : 'None'}',
                style: GoogleFonts.abel(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected Stylist: ${_selectedStylist ?? 'None'}',
                style: GoogleFonts.abel(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected Time: ${_selectedTime != null ? _selectedTime!.format(context) : "00:00"}',
                style: GoogleFonts.abel(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Price: Php $_totalPrice',
                style: GoogleFonts.abel(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _confirmAppointment(); // Proceed with appointment confirmation
              },
              child: const Text('CONFIRM'),
            ),
          ],
        );
      },
    );
  }

  // Widget to create category buttons
  Widget _buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedCategory = category;
          _selectedServices
              .clear(); // Clear selected services when category changes
          _selectedStylist =
              null; // Clear selected stylist when category changes
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedCategory == category
            ? Colors.green.shade700
            : Colors.grey.shade200,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(
        category,
        style: GoogleFonts.abel(
          textStyle: TextStyle(
            color: selectedCategory == category ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAppointment() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('salon')
            .doc(widget.salonId)
            .collection('appointments')
            .add({
          'userId': user.uid,
          'userName': _userName ?? 'Unknown User', // Name of the logged-in user
          'services': _selectedServices.map((s) {
            return {
              'name': s['name'],
              'main_category': s['main_category'],
              'price': s['price'],
            };
          }).toList(),

          'stylist': _selectedStylist ?? 'No stylist selected',
          'date': _selectedDay != null
              ? _selectedDay.toString().split(' ')[0]
              : 'No date selected',
          'time': _selectedTime != null
              ? _selectedTime!.format(context)
              : '00:00', // Save as "00:00" if not set
          'status': 'Pending',
          'totalPrice': _totalPrice, // Include total price in the appointment
          'timestamp':
              FieldValue.serverTimestamp(), // Add the current timestamp
        });

        // Show confirmation dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Appointment Confirmed'),
              content: const Text(
                  'Your appointment has been confirmed and is pending approval.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        print("Error adding appointment: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      print("User is not logged in");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make an appointment.')),
      );
    }
  }
}
