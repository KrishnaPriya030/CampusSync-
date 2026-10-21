import 'package:flutter/material.dart';

import '../services/certificate_template_service.dart';

class CertificateDesignerScreen extends StatefulWidget {
  const CertificateDesignerScreen({
    super.key,
    this.existingTemplate,
  });

  final Map<String, dynamic>? existingTemplate;

  @override
  State<CertificateDesignerScreen> createState() =>
      _CertificateDesignerScreenState();
}

class _CertificateDesignerScreenState
    extends State<CertificateDesignerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = CertificateTemplateService();

  late final TextEditingController _name;
  late final TextEditingController _organization;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _sign1Name;
  late final TextEditingController _sign1Role;
  late final TextEditingController _sign1Image;
  late final TextEditingController _sign2Name;
  late final TextEditingController _sign2Role;
  late final TextEditingController _sign2Image;
  late final TextEditingController _backgroundUrl;

  static const Color _page = Color(0xFF080B1A);
  static const Color _panel = Color(0xFF141832);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _gold = Color(0xFFD8B66A);

  static const List<Color> _colorChoices = [
    Color(0xFF4338CA),
    Color(0xFF0F766E),
    Color(0xFF1D4ED8),
    Color(0xFF7F1D1D),
    Color(0xFF111827),
    Color(0xFFB45309),
    Color(0xFFD8B66A),
    Color(0xFFCBD5E1),
    Color(0xFFFFFFFF),
  ];

  String _templateType = 'PARTICIPATION';
  String _font = 'SERIF';

  Color _primary = const Color(0xFF4338CA);
  Color _secondary = _gold;

  bool _saving = false;
  bool _preview = false;

  int? get _existingId {
    final value = widget.existingTemplate?['id'];

    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();

    final template =
        widget.existingTemplate ?? <String, dynamic>{};

    _name = TextEditingController(
      text: _text(template['name']),
    );

    _organization = TextEditingController(
      text: _text(template['organizationName']),
    );

    _title = TextEditingController(
      text: _text(
        template['certificateTitle'],
        fallback: 'Certificate of Participation',
      ),
    );

    _description = TextEditingController(
      text: _text(
        template['description'],
        fallback: 'This certificate is proudly presented to',
      ),
    );

    _sign1Name = TextEditingController(
      text: _text(template['signature1Name']),
    );

    _sign1Role = TextEditingController(
      text: _text(template['signature1Designation']),
    );

    _sign1Image = TextEditingController(
      text: _text(template['signature1ImageUrl']),
    );

    _sign2Name = TextEditingController(
      text: _text(template['signature2Name']),
    );

    _sign2Role = TextEditingController(
      text: _text(template['signature2Designation']),
    );

    _sign2Image = TextEditingController(
      text: _text(template['signature2ImageUrl']),
    );

    _backgroundUrl = TextEditingController(
      text: _text(template['backgroundUrl']),
    );

    const templateTypes = {
      'PARTICIPATION',
      'COMPLETION',
      'ACHIEVEMENT',
      'APPRECIATION',
    };

    final storedType =
        _text(template['templateType'], fallback: 'PARTICIPATION');

    _templateType = templateTypes.contains(storedType)
        ? storedType
        : 'PARTICIPATION';

    const fontTypes = {'SERIF', 'SANS_SERIF', 'SCRIPT'};

    final storedFont = _text(template['font'], fallback: 'SERIF');

    _font = fontTypes.contains(storedFont) ? storedFont : 'SERIF';

    _primary = _parseColor(
      template['primaryColor'],
      const Color(0xFF4338CA),
    );

    _secondary = _parseColor(
      template['secondaryColor'],
      _gold,
    );
  }

  String _text(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    final result = value.toString();

    return result == 'null' ? fallback : result;
  }

  Color _parseColor(dynamic raw, Color fallback) {
    if (raw == null) return fallback;

    var value = raw.toString().trim();

    if (value.startsWith('#')) {
      value = value.substring(1);
    } else if (value.startsWith('0x') ||
        value.startsWith('0X')) {
      value = value.substring(2);
    }

    if (value.length == 6) {
      value = 'FF$value';
    }

    if (value.length != 8) return fallback;

    final parsed = int.tryParse(value, radix: 16);

    return parsed == null ? fallback : Color(parsed);
  }

  String _hex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;

    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  void dispose() {
    _name.dispose();
    _organization.dispose();
    _title.dispose();
    _description.dispose();
    _sign1Name.dispose();
    _sign1Role.dispose();
    _sign1Image.dispose();
    _sign2Name.dispose();
    _sign2Role.dispose();
    _sign2Image.dispose();
    _backgroundUrl.dispose();

    super.dispose();
  }

  Future<void> _chooseColor({required bool primary}) async {
    final picked = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: _panel,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: _colorChoices.map((color) {
              return InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => Navigator.pop(context, color),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: color,
                  child: const Icon(
                    Icons.check,
                    color: Colors.black54,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (!mounted || picked == null) return;

    setState(() {
      if (primary) {
        _primary = picked;
      } else {
        _secondary = picked;
      }
    });
  }

  Map<String, dynamic> _payload() {
    String? optionalValue(TextEditingController controller) {
      final value = controller.text.trim();

      return value.isEmpty ? null : value;
    }

    return {
      'name': _name.text.trim(),
      'templateType': _templateType,
      'backgroundUrl': optionalValue(_backgroundUrl),
      'organizationName': _organization.text.trim(),
      'certificateTitle': _title.text.trim(),
      'description': _description.text.trim(),
      'signature1Name': optionalValue(_sign1Name),
      'signature1Designation': optionalValue(_sign1Role),
      'signature1ImageUrl': optionalValue(_sign1Image),
      'signature2Name': optionalValue(_sign2Name),
      'signature2Designation': optionalValue(_sign2Role),
      'signature2ImageUrl': optionalValue(_sign2Image),
      'font': _font,
      'primaryColor': _hex(_primary),
      'secondaryColor': _hex(_secondary),
    };
  }

  Future<void> _save() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _preview = false);
      return;
    }

    setState(() => _saving = true);

    try {
      final saved = await _api.saveTemplate(
        _payload(),
        id: _existingId,
      );

      if (!mounted) return;

      final savedId = int.tryParse(
        saved['id']?.toString() ?? '',
      );

      if (savedId == null || savedId <= 0) {
        throw Exception(
          'The server did not return a valid template ID.',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template saved successfully. ID: $savedId'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.of(context).pop(
        Map<String, dynamic>.from(saved),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error
          .toString()
          .replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: _panel,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _purple),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int lines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        style: const TextStyle(color: Colors.white),
        decoration: _dec(label, hint: hint),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required.';
                }

                return null;
              }
            : null,
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: _panel,
      style: const TextStyle(color: Colors.white),
      decoration: _dec(label),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page,
        foregroundColor: Colors.white,
        title: Text(
          _existingId == null
              ? 'Certificate Designer'
              : 'Edit Certificate',
        ),
        actions: [
          IconButton(
            tooltip: _preview ? 'Edit template' : 'Preview',
            onPressed: () {
              setState(() => _preview = !_preview);
            },
            icon: Icon(
              _preview
                  ? Icons.edit_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(),
              const SizedBox(height: 18),
              if (_preview)
                _certificatePreview()
              else ...[
                _section(
                  'Template details',
                  Icons.description_outlined,
                ),
                _field(
                  _name,
                  'Template name',
                  required: true,
                ),
                _dropdown<String>(
                  label: 'Certificate type',
                  value: _templateType,
                  items: const [
                    DropdownMenuItem(
                      value: 'PARTICIPATION',
                      child: Text('Participation'),
                    ),
                    DropdownMenuItem(
                      value: 'COMPLETION',
                      child: Text('Completion'),
                    ),
                    DropdownMenuItem(
                      value: 'ACHIEVEMENT',
                      child: Text('Achievement'),
                    ),
                    DropdownMenuItem(
                      value: 'APPRECIATION',
                      child: Text('Appreciation'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _templateType = value ?? 'PARTICIPATION';
                    });
                  },
                ),
                const SizedBox(height: 14),
                _field(
                  _organization,
                  'Organization / college name',
                  required: true,
                ),
                _field(
                  _title,
                  'Certificate heading',
                  required: true,
                ),
                _field(
                  _description,
                  'Certificate description',
                  lines: 3,
                  required: true,
                ),
                _field(
                  _backgroundUrl,
                  'Background image URL (optional)',
                  hint: 'https://example.com/background.png',
                ),
                _section(
                  'Visual style',
                  Icons.palette_outlined,
                ),
                _dropdown<String>(
                  label: 'Font style',
                  value: _font,
                  items: const [
                    DropdownMenuItem(
                      value: 'SERIF',
                      child: Text('Classic serif'),
                    ),
                    DropdownMenuItem(
                      value: 'SANS_SERIF',
                      child: Text('Modern sans-serif'),
                    ),
                    DropdownMenuItem(
                      value: 'SCRIPT',
                      child: Text('Elegant script'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _font = value ?? 'SERIF';
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _colorButton(
                        'Primary color',
                        _primary,
                        () => _chooseColor(primary: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _colorButton(
                        'Accent color',
                        _secondary,
                        () => _chooseColor(primary: false),
                      ),
                    ),
                  ],
                ),
                _section(
                  'Authorized signatures',
                  Icons.draw_outlined,
                ),
                _field(_sign1Name, 'First signer name'),
                _field(_sign1Role, 'First signer designation'),
                _field(
                  _sign1Image,
                  'First signature image URL (optional)',
                ),
                const Divider(
                  color: Colors.white12,
                  height: 28,
                ),
                _field(
                  _sign2Name,
                  'Second signer name (optional)',
                ),
                _field(
                  _sign2Role,
                  'Second signer designation',
                ),
                _field(
                  _sign2Image,
                  'Second signature image URL (optional)',
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () {
                              setState(() {
                                _preview = !_preview;
                              });
                            },
                      icon: Icon(
                        _preview
                            ? Icons.edit_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(
                        _preview ? 'Back to editor' : 'Preview certificate',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: _purple),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Saving...' : 'Save template',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF25205A),
            Color(0xFF151A36),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _purple.withValues(alpha: 0.35),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MAKE IT OFFICIAL',
            style: TextStyle(
              color: Color(0xFFC4B5FD),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Design your event certificate',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Customize the certificate, preview it, then save it to CampusSync.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFC4B5FD),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorButton(
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _certificatePreview() {
    return AspectRatio(
      aspectRatio: 1.414,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF2),
          border: Border.all(
            color: _secondary,
            width: 5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 14,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _primary,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                _organization.text.trim().isEmpty
                    ? 'YOUR ORGANIZATION'
                    : _organization.text.trim().toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                Icons.workspace_premium,
                size: 30,
                color: _secondary,
              ),
              Text(
                _title.text.trim().isEmpty
                    ? 'CERTIFICATE OF PARTICIPATION'
                    : _title.text.trim().toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                  fontFamily: _font == 'SERIF'
                      ? 'serif'
                      : _font == 'MONOSPACE'
                          ? 'monospace'
                          : null,
                  fontSize: 16,
                ),
              ),
              Text(
                _description.text.trim().isEmpty
                    ? 'This certificate is proudly presented to'
                    : _description.text.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 9,
                ),
              ),
              const Text(
                'STUDENT NAME',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                width: 90,
                height: 1,
                color: _secondary,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _signature(_sign1Name.text, _sign1Role.text),
                  _signature(_sign2Name.text, _sign2Role.text),
                ],
              ),
              const Text(
                'CAMPUSSYNC • CERTIFICATE PREVIEW',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 7,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signature(String name, String role) {
    return SizedBox(
      width: 105,
      child: Column(
        children: [
          Container(
            width: 78,
            height: 1,
            color: _primary,
          ),
          const SizedBox(height: 4),
          Text(
            name.trim().isEmpty ? 'Authorized Signer' : name.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            role.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }
}