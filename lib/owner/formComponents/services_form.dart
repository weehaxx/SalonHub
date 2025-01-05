import 'package:flutter/material.dart';

class ServicesForm extends StatefulWidget {
  final Map<String, List<Map<String, String>>> services;

  const ServicesForm({required this.services, super.key});

  @override
  _ServicesFormState createState() => _ServicesFormState();
}

class _ServicesFormState extends State<ServicesForm> {
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _servicePriceController = TextEditingController();
  final List<String> _categories = ['Hair', 'Nail', 'Spa', 'Others'];
  final List<String> _mainCategories = ['Male', 'Female'];
  String? _selectedMainCategory;
  String? _selectedCategory;

  void _addService() {
    if (_serviceNameController.text.isNotEmpty &&
        _servicePriceController.text.isNotEmpty &&
        _selectedMainCategory != null &&
        _selectedCategory != null) {
      if (_selectedMainCategory != null &&
          widget.services[_selectedMainCategory!]!.any(
              (service) => service['name'] == _serviceNameController.text)) {
        // Check for duplicate service name in the selected main category
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Service name already exists in the ${_selectedMainCategory!} category.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        widget.services[_selectedMainCategory!]?.add({
          'name': _serviceNameController.text,
          'price': _servicePriceController.text,
          'category': _selectedCategory!,
        });
        _serviceNameController.clear();
        _servicePriceController.clear();
        _selectedCategory = null;
        _selectedMainCategory = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff355E3B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    'Main Category',
                    _mainCategories,
                    (newValue) {
                      setState(() {
                        _selectedMainCategory = newValue;
                      });
                    },
                  ),
                  _buildDropdownField(
                    'Category',
                    _categories,
                    (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                  _buildTextField('Service Name', _serviceNameController),
                  _buildNumberField('Service Price', _servicePriceController),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _addService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff355E3B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Add Service',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildServiceList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.services['Male']!.isNotEmpty) ...[
          const Text(
            'Male Services',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff355E3B),
            ),
          ),
          const SizedBox(height: 10),
          _buildServiceCategoryList('Male'),
        ],
        if (widget.services['Female']!.isNotEmpty) ...[
          const Text(
            'Female Services',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff355E3B),
            ),
          ),
          const SizedBox(height: 10),
          _buildServiceCategoryList('Female'),
        ],
      ],
    );
  }

  Widget _buildServiceCategoryList(String category) {
    final services = widget.services[category]!;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
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
              service['name'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff355E3B),
              ),
            ),
            subtitle: Text(
              'Price: \₱${service['price']} | Category: ${service['category']}',
              style: const TextStyle(
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  widget.services[category]?.removeAt(index);
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

  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
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

  Widget _buildDropdownField(
      String label, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: label == 'Main Category'
            ? _selectedMainCategory
            : _selectedCategory,
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
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
