import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/organizer.dart';
import '../storage/token_storage.dart';

class AdminOrganizerActivationScreen extends StatefulWidget {
  const AdminOrganizerActivationScreen({
    super.key,
  });

  @override
  State<AdminOrganizerActivationScreen> createState() =>
      _AdminOrganizerActivationScreenState();
}

class _AdminOrganizerActivationScreenState
    extends State<AdminOrganizerActivationScreen> {
  static const String baseUrl = 'http://127.0.0.1:8080';

  final TokenStorage _tokenStorage = TokenStorage();

  List<Organizer> _organizers = [];

  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrganizers();
  }

  Future<void> _loadOrganizers() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/organizers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load organizers: '
          '${response.statusCode}\n${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Invalid organizers response');
      }

      final organizers = decoded
          .map(
            (item) => Organizer.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _organizers = organizers;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load organizers error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Failed to load organizers\n$e',
      );
    }
  }

  Future<void> _activateOrganizer(
    Organizer organizer,
  ) async {
    await _changeOrganizerStatus(
      organizer,
      activate: true,
    );
  }

  Future<void> _deactivateOrganizer(
    Organizer organizer,
  ) async {
    await _changeOrganizerStatus(
      organizer,
      activate: false,
    );
  }

  Future<void> _changeOrganizerStatus(
    Organizer organizer, {
    required bool activate,
  }) async {
    if (_actionLoading) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      final token = await _tokenStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final endpoint = activate
          ? '/api/admin/organizers/${organizer.id}/activate'
          : '/api/admin/organizers/${organizer.id}/block';

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}\n'
          '${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid organizer response');
      }

      final updatedOrganizer =
          Organizer.fromJson(decoded);

      if (!mounted) return;

      setState(() {
        final index = _organizers.indexWhere(
          (item) => item.id == updatedOrganizer.id,
        );

        if (index != -1) {
          _organizers[index] = updatedOrganizer;
        }
      });

      _showMessage(
        activate
            ? 'Organizer activated successfully'
            : 'Organizer deactivated successfully',
      );
    } catch (e) {
      debugPrint(
        'Organizer status change error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Failed to change organizer status\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060917),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF060917),
              Color(0xFF0B1430),
              Color(0xFF171033),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadOrganizers,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _organizers.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          30,
                        ),
                        itemCount: _organizers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildOrganizerCard(
                            _organizers[index],
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.verified_user_outlined,
          size: 64,
          color: Colors.white.withOpacity(0.25),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'No organizers found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Create an organizer from the Organizers section.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.50),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerCard(
    Organizer organizer,
  ) {
    final status =
        organizer.accountStatus.toUpperCase();

    final isActive = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6)
                      .withOpacity(0.14),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFC4B5FD),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      organizer.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              _statusBadge(
                status,
                isActive,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _infoRow(
            Icons.business_outlined,
            organizer.organizationName,
          ),

          const SizedBox(height: 8),

          _infoRow(
            Icons.work_outline_rounded,
            organizer.designation,
          ),

          if (organizer.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(
              Icons.phone_outlined,
              organizer.phoneNumber,
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _actionLoading || isActive
                      ? null
                      : () => _activateOrganizer(
                            organizer,
                          ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                  ),
                  label: const Text('Activate'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _actionLoading || !isActive
                      ? null
                      : () => _deactivateOrganizer(
                            organizer,
                          ),
                  icon: const Icon(
                    Icons.block_outlined,
                  ),
                  label: const Text('Deactivate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
    bool active,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(0.10)
            : Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: active
              ? Colors.greenAccent
              : Colors.orangeAccent,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withOpacity(0.35),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}