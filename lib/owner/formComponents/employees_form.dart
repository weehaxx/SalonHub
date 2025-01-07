import 'package:flutter/material.dart';

class EmployeesForm extends StatefulWidget {
  final List<Map<String, dynamic>> employees; // Correctly type employees
  final List<String> allRegisteredStylistNames;

  const EmployeesForm({
    required this.employees,
    required this.allRegisteredStylistNames,
    super.key,
  });

  @override
  _EmployeesFormState createState() => _EmployeesFormState();
}

class _EmployeesFormState extends State<EmployeesForm> {
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeSpecializationController =
      TextEditingController();

  final List<String> _categories = ['Hair', 'Nail', 'Spa', 'Others'];
  final Set<String> _selectedCategories = {};

  // Add Employee Function
  void _addEmployee() {
    final String employeeName = _employeeNameController.text.trim();
    final String specialization = _employeeSpecializationController.text.trim();

    // Check for duplicate employees
    final bool isDuplicateInCurrentSalon = widget.employees.any(
      (employee) =>
          (employee['name']?.toString().toLowerCase() ?? '') ==
          employeeName.toLowerCase(),
    );

    final bool isDuplicateGlobally = widget.allRegisteredStylistNames.any(
      (name) => name.toLowerCase() == employeeName.toLowerCase(),
    );

    // Validate input fields
    if (employeeName.isEmpty ||
        specialization.isEmpty ||
        _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill out all employee fields and select at least one category.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isDuplicateInCurrentSalon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Stylist "$employeeName" is already registered in this salon!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isDuplicateGlobally) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Stylist "$employeeName" is already registered in another salon!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add Employee
    setState(() {
      widget.employees.add({
        'name': employeeName,
        'specialization': specialization,
        'categories': _selectedCategories.toList(), // Convert Set to List
        'status': 'Available',
      });

      widget.allRegisteredStylistNames.add(employeeName);
      _employeeNameController.clear();
      _employeeSpecializationController.clear();
      _selectedCategories.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stylist added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employees',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xff355E3B),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Employee Full Name', _employeeNameController),
            _buildTextField(
                'Specialization', _employeeSpecializationController),
            _buildCategorySelector(),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _addEmployee,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff355E3B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Add Employee',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            _buildEmployeeList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.employees.length,
      itemBuilder: (context, index) {
        final employee = widget.employees[index];

        // Ensure categories are handled as List<String>
        final List<String> categories = (employee['categories'] is List)
            ? (employee['categories'] as List).map((e) => e.toString()).toList()
            : (employee['categories'] is String)
                ? employee['categories']
                    .split(',')
                    .map((e) => e.trim())
                    .toList()
                : [];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.2),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            title: Text(
              employee['name'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff355E3B),
              ),
            ),
            subtitle: Text(
              'Specialization: ${employee['specialization'] ?? ''}\nCategories: ${categories.join(', ')}',
              style: const TextStyle(
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  widget.allRegisteredStylistNames.remove(employee['name']);
                  widget.employees.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
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
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff355E3B),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _categories.map((category) {
              return FilterChip(
                label: Text(
                  category,
                  style: TextStyle(
                    color: _selectedCategories.contains(category)
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                selected: _selectedCategories.contains(category),
                selectedColor: const Color(0xff355E3B),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                backgroundColor: Colors.grey.shade200,
                checkmarkColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
