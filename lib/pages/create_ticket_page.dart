import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_window_bar.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  int _level = 2; // Medium by default
  bool _isLoading = false;
  File? _selectedImage;

  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      final lang = Provider.of<LanguageProvider>(context, listen: false);

      try {
        final imageUrl = await ApiService().uploadImage(pickedFile.path);
        if (imageUrl != null) {
          setState(() {
            _messageController.text += '\n\n![Image]($imageUrl)';
            _selectedImage = File(pickedFile.path); // Optional: keep for UI feedback if needed, or remove
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(lang.getText('image_uploaded'))),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image upload failed')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    try {
      final error = await ApiService().createTicket(
        _subjectController.text,
        _level,
        _messageController.text,
      );

      if (error == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lang.getText('ticket_created'))),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.getText('create_ticket'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lang.getText('subject'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: lang.getText('enter_subject'),
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text(lang.getText('level'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _level,
                dropdownColor: AppTheme.surfaceColor,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text(lang.getText('low'))),
                  DropdownMenuItem(value: 2, child: Text(lang.getText('medium'))),
                  DropdownMenuItem(value: 3, child: Text(lang.getText('high'))),
                ],
                onChanged: (value) => setState(() => _level = value!),
              ),
              const SizedBox(height: 16),
              Text(lang.getText('message'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: lang.getText('enter_message'),
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadImage,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.image, color: Colors.white),
                    label: Text(
                      _isUploading ? 'Uploading...' : lang.getText('upload_image'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(lang.getText('confirm'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
