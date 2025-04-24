// File: lib/screens/ticket_details_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';

class TicketDetailsScreen extends StatefulWidget {
  final String orderId;
  final String ticketCode;
  const TicketDetailsScreen({
    Key? key,
    required this.orderId,
    required this.ticketCode,
  }) : super(key: key);

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final ApiService _api = ApiService();
  Ticket? _ticket;
  bool _loading = true;
  String? _error;

  static const int _intervalSeconds = 30;
  int _remainingSeconds = _intervalSeconds;
  late String _dynamicCode;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await _api.getTicketDetails(widget.orderId);
      setState(() {
        _ticket = Ticket.fromJson(data);
        _loading = false;
      });
      if (!_ticket!.validado) _startQrCycle();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startQrCycle() {
    _generateDynamicCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _generateDynamicCode();
          _remainingSeconds = _intervalSeconds;
        }
      });
    });
  }

  void _generateDynamicCode() {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final window = ts ~/ _intervalSeconds;
    _dynamicCode = '${widget.ticketCode}-$window';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      appBar: AppBar(
        title: const Text('Detalhes do Ingresso'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro: $_error'))
              : _ticket!.validado
                  ? _buildValidatedView(context)
                  : _buildQrView(context),
    );
  }

  /// Se já validado: mostra selo e resumo
  Widget _buildValidatedView(BuildContext context) {
    final t = _ticket!;
    final dateFmt = DateFormat('dd MMMM yyyy', 'pt_BR');
    final horaStr = t.eventoHorario.format(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded,
              size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text('Ingresso Validado',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.green)),
          const SizedBox(height: 32),

          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.eventoNome,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text(dateFmt.format(t.eventoData)),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(horaStr),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(t.eventoLocal)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _sectionCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title:
                      Text('${t.purchaserName} ${t.purchaserSurname}'),
                  subtitle: const Text('Comprador'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.confirmation_number),
                  title: Text(t.ticketCode),
                  subtitle: const Text('Ticket Code'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Se não validado: mostra QR e contador
  Widget _buildQrView(BuildContext context) {
    final t = _ticket!;
    final dateFmt = DateFormat('dd MMMM yyyy', 'pt_BR');
    final horaStr = t.eventoHorario.format(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = screenWidth * 0.6;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Evento header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(t.eventoNome,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _iconInfo(
                          icon: Icons.calendar_today,
                          text: dateFmt.format(t.eventoData)),
                      _iconInfo(
                          icon: Icons.access_time, text: horaStr),
                      _iconInfo(
                          icon: Icons.location_on,
                          text: t.eventoLocal),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // QR card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _sectionCard(
              child: Column(
                children: [
                  QrImageView(
                    data: _dynamicCode,
                    size: qrSize,
                    backgroundColor:
                        Theme.of(context).colorScheme.surface,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _remainingSeconds / _intervalSeconds,
                    minHeight: 6,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text('Recarrega em $_remainingSeconds s'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Comprador e código
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _sectionCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title:
                        Text('${t.purchaserName} ${t.purchaserSurname}'),
                    subtitle: const Text('Comprador'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.confirmation_number),
                    title: Text(t.ticketCode),
                    subtitle: const Text('Ticket Code'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.check_circle),
                    title: Text(
                        '${t.status[0].toUpperCase()}${t.status.substring(1).toLowerCase()}'),
                    subtitle: const Text('Status'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _iconInfo({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
