import 'package:flutter/material.dart';

class EmployeesForm extends StatefulWidget {
  final List<Map<String, String>> employees;

  const EmployeesForm({required this.employees, super.key});

  @override
  _EmployeesFormState createState() => _EmployeesFormState();
}

class _EmployeesFormState extends State<EmployeesForm> {
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeSpecializationController =
      TextEditingController();

  final List<String> _categories = [
    'Hair',
    'Nail',
    'Massage',
    'Others',
  ];

  final List<String> _selectedCategories = [];

  void _addEmployee() {
    if (_employeeNameController.text.isNotEmpty &&
        _employeeSpecializationController.text.isNotEmpty &&
        _selectedCategories.isNotEmpty) {
      setState(() {
        widget.employees.add({
          'name': _employeeNameController.text,
          'specialization': _employeeSpecializationController.text,
          'categories': _selectedCategories.join(', '),
          'status': 'Available',
        });
        _employeeNameController.clear();
        _employeeSpecializationController.clear();
        _selectedCategories.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill out all employee fields and select at least one category.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            _buildTextField('Employee Name', _employeeNameController),
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
                      'Specialization: ${employee['specialization']}\nCategories: ${employee['categories']}',
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
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
