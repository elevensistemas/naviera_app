import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../models/models.dart';

class ReportIncidentView extends StatefulWidget {
  final VoidCallback onIncidentReported;
  const ReportIncidentView({super.key, required this.onIncidentReported});

  @override
  State<ReportIncidentView> createState() => _ReportIncidentViewState();
}

class _ReportIncidentViewState extends State<ReportIncidentView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  List<Ship> _ships = [];
  String? _selectedShipId;
  String _selectedCode = "MG-21";
  String _selectedType = "unsafe_act";
  
  bool _loadingShips = true;
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  XFile? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    _loadShips();
  }

  Future<void> _loadShips() async {
    try {
      final ships = await FleetService().fetchShips();
      setState(() {
        _ships = ships;
        if (ships.isNotEmpty) {
          _selectedShipId = ships.first.id;
        }
        _loadingShips = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingShips = false;
        });
      }
    }
  }

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
    final shipId = _selectedShipId;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (shipId == null || title.isEmpty || description.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final incidentService = IncidentService();
      final photos = <Uint8List>[];
      if (_selectedImageBytes != null) {
        photos.add(_selectedImageBytes!);
      }
      
      await incidentService.reportIncident(
        description: description,
        shipId: shipId,
        code: _selectedCode,
        type: _selectedType,
        title: title,
        photos: photos,
      );
      
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
    final isFormValid = _selectedShipId != null && 
        _titleController.text.trim().isNotEmpty && 
        _descriptionController.text.trim().isNotEmpty;

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
            const SizedBox(height: 16),
            
            // Embarcación Dropdown
            Text(
              "Embarcación",
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _loadingShips
                ? const SizedBox(
                    height: 52,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedShipId,
                    dropdownColor: theme.colorScheme.surface,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _ships.map((ship) {
                      return DropdownMenuItem<String>(
                        value: ship.id,
                        child: Text(ship.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedShipId = val;
                      });
                    },
                  ),
            const SizedBox(height: 16),

            // Code & Type Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Código Reporte",
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCode,
                        dropdownColor: theme.colorScheme.surface,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: "MG-21", child: Text("MG-21")),
                          DropdownMenuItem(value: "MG-06", child: Text("MG-06")),
                          DropdownMenuItem(value: "MG-07", child: Text("MG-07")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCode = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tipo de Incidente",
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        dropdownColor: theme.colorScheme.surface,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: "unsafe_act", child: Text("Acto Inseguro")),
                          DropdownMenuItem(value: "unsafe_condition", child: Text("Condición Insegura")),
                          DropdownMenuItem(value: "near_miss", child: Text("Casi Accidente")),
                          DropdownMenuItem(value: "personal_accident", child: Text("Accidente Personal")),
                          DropdownMenuItem(value: "nautical_incident", child: Text("Incidente Náutico")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedType = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Título Breve
            Text(
              "Título Breve",
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Ej: Falla en equipo de extinción",
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Descripción de los Hechos
            Text(
              "Descripción de los Hechos",
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Detalle los hechos o novedades del incidente...",
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
