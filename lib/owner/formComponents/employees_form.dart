import 'package:flutter/material.dart';

class EmployeesForm extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
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

  void _addEmployee() {
    final employeeName = _employeeNameController.text.trim();
    final specialization = _employeeSpecializationController.text.trim();

    final isDuplicateInCurrentSalon = widget.employees.any(
      (employee) =>
          employee['name']?.toLowerCase() == employeeName.toLowerCase(),
    );

    final isDuplicateGlobally = widget.allRegisteredStylistNames.any(
      (name) => name.toLowerCase() == employeeName.toLowerCase(),
    );

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

    setState(() {
      widget.employees.add({
        'name': employeeName,
        'specialization': specialization,
        'categories': _selectedCategories.toList(), // Store as a list
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.employees.length,
              itemBuilder: (context, index) {
                final employee = widget.employees[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  shadowColor: Colors.grey.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    title: Text(
                      employee['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff355E3B),
                      ),
                    ),
                    subtitle: Text(
                      'Specialization: ${employee['specialization']}\nCategories: ${employee['categories'].join(', ')}',
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          widget.allRegisteredStylistNames
                              .remove(employee['name']); // Remove globally
                          widget.employees.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
