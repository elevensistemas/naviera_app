import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/services.dart';
import '../../app/theme.dart';

class ReportIncidentView extends StatefulWidget {
  final VoidCallback onIncidentReported;
  const ReportIncidentView({super.key, required this.onIncidentReported});

  @override
  State<ReportIncidentView> createState() => _ReportIncidentViewState();
}

class _ReportIncidentViewState extends State<ReportIncidentView> {
  final _shipIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  XFile? _selectedImageFile;

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _selectedImageBytes = bytes;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitReport() async {
    final shipId = _shipIdController.text.trim();
    final description = _descriptionController.text.trim();

    if (shipId.isEmpty || description.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final incidentService = IncidentService();
      final photos = <Uint8List>[];
      if (_selectedImageBytes != null) {
        photos.add(_selectedImageBytes!);
      }
      await incidentService.reportIncident(description, shipId, photos);
      widget.onIncidentReported();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al reportar incidente: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFormValid = _shipIdController.text.trim().isNotEmpty && _descriptionController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Incidente", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar", style: TextStyle(color: theme.colorScheme.onSurface)),
        ),
        leadingWidth: 80,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Section
            Text(
              "Detalles del Incidente",
              style: TypographyTheme.headline(context),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _shipIdController,
              decoration: InputDecoration(
                hintText: "Identificador de Barco (Ej. s1)",
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describa lo ocurrido con el mayor detalle posible...",
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            
            const SizedBox(height: 24),
            
            // Evidence Section
            Text(
              "Evidencia",
              style: TypographyTheme.headline(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorTheme.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, color: ColorTheme.accent),
              label: Text(
                _selectedImageBytes == null ? "Adjuntar Fotografía" : "Cambiar Fotografía",
                style: const TextStyle(color: ColorTheme.accent),
              ),
            ),
            
            if (_selectedImageBytes != null) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: MemoryImage(_selectedImageBytes!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid ? ColorTheme.danger : theme.colorScheme.surface,
                  foregroundColor: isFormValid ? Colors.white : Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: (isFormValid && !_isLoading) ? _submitReport : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Enviar Reporte HSE",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shipIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
