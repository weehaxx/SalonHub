import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SalonImages extends StatefulWidget {
  const SalonImages({super.key});

  @override
  State<SalonImages> createState() => _SalonImagesState();
}

class _SalonImagesState extends State<SalonImages> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String? salonImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSalonImage();
  }

  Future<void> fetchSalonImage() async {
    try {
      final salonDoc = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .get();

      if (salonDoc.exists) {
        final data = salonDoc.data();
        setState(() {
          salonImage = data?['image_url'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching salon image: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> uploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Upload the image to Firebase Storage
        String fileName = pickedFile.name;
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('salon_images/${_user?.uid}/$fileName');

        UploadTask uploadTask = storageRef.putFile(imageFile);

        // Retrieve the download URL
        TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
        String downloadURL = await snapshot.ref.getDownloadURL();

        // Update Firestore with the new image, replacing the existing one
        await FirebaseFirestore.instance
            .collection('salon')
            .doc(_user?.uid)
            .update({
          'image_url': downloadURL,
        });

        setState(() {
          salonImage = downloadURL;
        });

        // Log the image upload action
        await _logAction(
          actionType: 'Salon Image Changed',
          description: 'Salon image was uploaded or replaced.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image.')),
      );
    }
  }

  Future<void> deleteImage() async {
    if (salonImage == null) return;

    bool confirmDeletion = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Image'),
            content: const Text('Are you sure you want to delete this image?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDeletion) return;

    try {
      Reference storageRef = FirebaseStorage.instance.refFromURL(salonImage!);
      await storageRef.delete();

      // Remove the image URL from Firestore
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .update({
        'image_url': FieldValue.delete(),
      });

      setState(() {
        salonImage = null;
      });

      // Log the image deletion action
      await _logAction(
        actionType: 'Salon Image Deleted',
        description: 'Salon image was deleted.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete image.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon Image'),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : salonImage == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No image found. Add your first image!',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: uploadImage,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff355E3B),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showFullImage(context, salonImage!),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              salonImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: uploadImage,
                          icon: const Icon(Icons.edit),
                          label: const Text('Replace Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff355E3B),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: deleteImage,
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(imageUrl),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
