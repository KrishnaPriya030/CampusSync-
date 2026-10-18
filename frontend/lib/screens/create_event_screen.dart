
import 'package:flutter/material.dart';

import '../../services/organizer_event_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final OrganizerEventService _eventService = OrganizerEventService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _capacityController = TextEditingController(text: '100');
  final _feeController = TextEditingController(text: '0');
  final _refundPolicyController = TextEditingController();
  final _certificateTemplateController = TextEditingController();

  DateTime? _startDateTime;
  DateTime? _endDateTime;
  DateTime? _registrationDeadline;

  String _scope = 'ORGANIZATION';
  String _capacityType = 'LIMITED';
  String _paymentType = 'FREE';

  bool _attendanceEnabled = false;
  bool _certificateEnabled = false;
  bool _isSubmitting = false;

  static const Color _background = Color(0xFF060917);
  static const Color _surface = Color(0xFF11152D);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _lavender = Color(0xFFC4B5FD);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    _feeController.dispose();
    _refundPolicyController.dispose();
    _certificateTemplateController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({
    required DateTime? currentValue,
    required ValueChanged<DateTime> onSelected,
    required String label,
  }) async {
    final now = DateTime.now();

    final initial = currentValue ?? now.add(const Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select $label date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _purple,
              surface: _surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentValue != null
          ? TimeOfDay.fromDateTime(currentValue)
          : const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _purple,
              surface: _surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    onSelected(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Select date and time';

    final date =
        '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$date • $hour:$minute $period';
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _validateCapacity(String? value) {
    if (_capacityType == 'UNLIMITED') return null;

    if (value == null || value.trim().isEmpty) {
      return 'Enter the event capacity.';
    }

    final capacity = int.tryParse(value.trim());

    if (capacity == null || capacity <= 0) {
      return 'Capacity must be a positive whole number.';
    }

    return null;
  }

  String? _validateFee(String? value) {
    if (_paymentType == 'FREE') return null;

    if (value == null || value.trim().isEmpty) {
      return 'Enter the registration fee.';
    }

    final fee = double.tryParse(value.trim());

    if (fee == null || fee < 0) {
      return 'Enter a valid non-negative fee.';
    }

    return null;
  }

  String? _validateDates() {
    if (_startDateTime == null ||
        _endDateTime == null ||
        _registrationDeadline == null) {
      return 'Select the start, end and registration deadline.';
    }

    if (!_endDateTime!.isAfter(_startDateTime!)) {
      return 'The end time must be after the start time.';
    }

    if (!_registrationDeadline!.isBefore(_startDateTime!)) {
      return 'The registration deadline must be before the event starts.';
    }

    if (!_startDateTime!.isAfter(DateTime.now())) {
      return 'The event start time must be in the future.';
    }

    if (_registrationDeadline!.isBefore(DateTime.now())) {
      return 'The registration deadline must be in the future.';
    }

    return null;
  }

  Future<void> _submitEvent() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final dateError = _validateDates();

    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateError),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    int? certificateTemplateId;

    if (_certificateEnabled) {
      certificateTemplateId =
          int.tryParse(_certificateTemplateController.text.trim());

      if (certificateTemplateId == null || certificateTemplateId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a valid existing certificate template ID.',
            ),
          ),
        );
        return;
      }
    }

    final eventData = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'venue': _venueController.text.trim(),
      'startDateTime': _startDateTime!.toIso8601String(),
      'endDateTime': _endDateTime!.toIso8601String(),
      'registrationDeadline': _registrationDeadline!.toIso8601String(),
      'scope': _scope,
      'capacityType': _capacityType,
      'capacity': _capacityType == 'LIMITED'
          ? int.parse(_capacityController.text.trim())
          : null,
      'paymentType': _paymentType,
      'registrationFee': _paymentType == 'PAID'
          ? double.parse(_feeController.text.trim())
          : 0,
      'refundPolicy': _refundPolicyController.text.trim(),
      'attendanceEnabled': _attendanceEnabled,
      'certificateEnabled': _certificateEnabled,
      'certificateTemplateId':
          _certificateEnabled ? certificateTemplateId : null,
    };

    setState(() => _isSubmitting = true);

    try {
      await _eventService.createEvent(eventData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event saved successfully as a draft.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      // Return to the dashboard and signal that events should reload.
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Event',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _sectionTitle('Event details', Icons.event_note_rounded),
              const SizedBox(height: 12),
              _textField(
                controller: _titleController,
                label: 'Event title',
                hint: 'Enter a clear event name',
                icon: Icons.title_rounded,
                validator: (value) =>
                    _validateRequired(value, 'Event title'),
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe the event and its purpose',
                icon: Icons.description_outlined,
                maxLines: 4,
                validator: (value) =>
                    _validateRequired(value, 'Description'),
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _venueController,
                label: 'Venue',
                hint: 'Enter the event location',
                icon: Icons.location_on_outlined,
                validator: (value) => _validateRequired(value, 'Venue'),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Schedule', Icons.schedule_rounded),
              const SizedBox(height: 12),
              _dateField(
                label: 'Event starts',
                value: _startDateTime,
                onTap: () => _pickDateTime(
                  currentValue: _startDateTime,
                  label: 'event start',
                  onSelected: (value) =>
                      setState(() => _startDateTime = value),
                ),
              ),
              const SizedBox(height: 12),
              _dateField(
                label: 'Event ends',
                value: _endDateTime,
                onTap: () => _pickDateTime(
                  currentValue: _endDateTime ?? _startDateTime,
                  label: 'event end',
                  onSelected: (value) =>
                      setState(() => _endDateTime = value),
                ),
              ),
              const SizedBox(height: 12),
              _dateField(
                label: 'Registration deadline',
                value: _registrationDeadline,
                onTap: () => _pickDateTime(
                  currentValue: _registrationDeadline,
                  label: 'registration deadline',
                  onSelected: (value) =>
                      setState(() => _registrationDeadline = value),
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Audience and capacity', Icons.groups_rounded),
              const SizedBox(height: 12),
              _dropdownField(
                label: 'Event scope',
                value: _scope,
                icon: Icons.public_rounded,
                items: const [
                  DropdownMenuItem(
                    value: 'DEPARTMENT',
                    child: Text('Department'),
                  ),
                  DropdownMenuItem(
                    value: 'ORGANIZATION',
                    child: Text('Organization / college-wide'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _scope = value);
                },
              ),
              const SizedBox(height: 12),
              _dropdownField(
                label: 'Capacity type',
                value: _capacityType,
                icon: Icons.people_alt_outlined,
                items: const [
                  DropdownMenuItem(
                    value: 'LIMITED',
                    child: Text('Limited seats'),
                  ),
                  DropdownMenuItem(
                    value: 'UNLIMITED',
                    child: Text('Unlimited seats'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _capacityType = value);
                  }
                },
              ),
              if (_capacityType == 'LIMITED') ...[
                const SizedBox(height: 12),
                _textField(
                  controller: _capacityController,
                  label: 'Maximum participants',
                  hint: 'e.g. 100',
                  icon: Icons.format_list_numbered_rounded,
                  keyboardType: TextInputType.number,
                  validator: _validateCapacity,
                ),
              ],
              const SizedBox(height: 24),
              _sectionTitle('Registration and payment', Icons.payments_rounded),
              const SizedBox(height: 12),
              _dropdownField(
                label: 'Payment type',
                value: _paymentType,
                icon: Icons.account_balance_wallet_outlined,
                items: const [
                  DropdownMenuItem(
                    value: 'FREE',
                    child: Text('Free event'),
                  ),
                  DropdownMenuItem(
                    value: 'PAID',
                    child: Text('Paid event'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _paymentType = value);
                },
              ),
              if (_paymentType == 'PAID') ...[
                const SizedBox(height: 12),
                _textField(
                  controller: _feeController,
                  label: 'Registration fee (₹)',
                  hint: 'e.g. 250',
                  icon: Icons.currency_rupee_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateFee,
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _refundPolicyController,
                  label: 'Refund policy',
                  hint: 'Explain the refund conditions',
                  icon: Icons.policy_outlined,
                  maxLines: 3,
                  validator: (value) =>
                      _validateRequired(value, 'Refund policy'),
                ),
              ],
              const SizedBox(height: 24),
              _sectionTitle('Event features', Icons.tune_rounded),
              const SizedBox(height: 12),
              _switchCard(
                title: 'Attendance tracking',
                subtitle: 'Enable attendance recording for this event.',
                icon: Icons.fact_check_outlined,
                value: _attendanceEnabled,
                onChanged: (value) =>
                    setState(() => _attendanceEnabled = value),
              ),
              const SizedBox(height: 10),
              _switchCard(
                title: 'Certificates',
                subtitle: 'Enable certificates for eligible participants.',
                icon: Icons.workspace_premium_outlined,
                value: _certificateEnabled,
                onChanged: (value) =>
                    setState(() => _certificateEnabled = value),
              ),
              if (_certificateEnabled) ...[
                const SizedBox(height: 12),
                _textField(
                  controller: _certificateTemplateController,
                  label: 'Certificate template ID',
                  hint: 'Enter an existing template ID',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (!_certificateEnabled) return null;

                    final id = int.tryParse(value?.trim() ?? '');

                    if (id == null || id <= 0) {
                      return 'Enter a valid certificate template ID.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use an ID that already exists in the backend. '
                  'This form does not create certificate templates.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitEvent,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSubmitting ? 'Saving event...' : 'Save as draft',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _purple.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Saving creates a draft. Submit it for approval from My Events.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171033), Color(0xFF0B1430)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _lavender.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Color(0x338B5CF6),
            child: Icon(
              Icons.add_task_rounded,
              color: _lavender,
              size: 27,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan something meaningful',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Enter the event details and save a draft.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _lavender, size: 21),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _lavender, size: 21),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        errorStyle: const TextStyle(fontSize: 11),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: _surface,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _lavender, size: 21),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.calendar_month_rounded,
            color: _lavender,
            size: 21,
          ),
          suffixIcon: const Icon(
            Icons.access_time_rounded,
            color: Colors.white54,
            size: 20,
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: _surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Text(
          _formatDateTime(value),
          style: TextStyle(
            color: value == null ? Colors.white38 : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _lavender, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: _lavender,
            activeTrackColor: _purple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
