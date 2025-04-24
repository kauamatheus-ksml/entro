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

class _TicketDetailsScreenState extends State<TicketDetailsScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Ticket? _ticket;
  bool _loading = true;
  String? _error;

  static const int _intervalSeconds = 30;
  int _remainingSeconds = _intervalSeconds;
  late String _dynamicCode;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Detalhes do Ingresso'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando detalhes...',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 68,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar detalhes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchDetails,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _ticket!.validado
                  ? _buildValidatedView(context)
                  : _buildQrView(context),
    );
  }

  /// Se já validado: mostra selo e resumo
  Widget _buildValidatedView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = _ticket!;
    final dateFmt = DateFormat('dd MMMM yyyy', 'pt_BR');
    final horaStr = t.eventoHorario.format(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          // Validated banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ingresso Validado',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'O ingresso já foi utilizado',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Event details card
          _sectionCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.event,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalhes do Evento',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.eventoNome,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _infoRow(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Data',
                  value: dateFmt.format(t.eventoData),
                ),
                const SizedBox(height: 12),
                _infoRow(
                  context,
                  icon: Icons.access_time,
                  title: 'Hora',
                  value: horaStr,
                ),
                const SizedBox(height: 12),
                _infoRow(
                  context,
                  icon: Icons.location_on,
                  title: 'Local',
                  value: t.eventoLocal,
                ),
                if (t.tipoIngresso != null) ...[
                  const SizedBox(height: 12),
                  _infoRow(
                    context,
                    icon: Icons.confirmation_number,
                    title: 'Tipo de Ingresso',
                    value: t.tipoIngresso!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Purchaser details card
          _sectionCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comprador',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${t.purchaserName} ${t.purchaserSurname}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _infoRow(
                  context,
                  icon: Icons.confirmation_number,
                  title: 'Código do ingresso',
                  value: t.ticketCode,
                ),
                const SizedBox(height: 12),
                _infoRow(
                  context,
                  icon: Icons.shopping_cart,
                  title: 'Número do pedido',
                  value: t.orderId,
                ),
                const SizedBox(height: 12),
                _infoRow(
                  context,
                  icon: Icons.check_circle,
                  title: 'Status',
                  value: '${t.status[0].toUpperCase()}${t.status.substring(1).toLowerCase()}',
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
    final colorScheme = Theme.of(context).colorScheme;
    final t = _ticket!;
    final dateFmt = DateFormat('dd MMMM yyyy', 'pt_BR');
    final horaStr = t.eventoHorario.format(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = screenWidth * 0.6;

    // Verifica se o evento já passou
    final bool isPastEvent = t.eventoData.isBefore(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Event header card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _sectionCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Evento nome
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.eventoNome,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Icons and info row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _iconInfoColumn(
                          context,
                          icon: Icons.calendar_today,
                          title: 'Data',
                          text: dateFmt.format(t.eventoData),
                        ),
                        _divider(),
                        _iconInfoColumn(
                          context,
                          icon: Icons.access_time,
                          title: 'Hora',
                          text: horaStr,
                        ),
                        _divider(),
                        _iconInfoColumn(
                          context,
                          icon: Icons.location_on,
                          title: 'Local',
                          text: t.eventoLocal,
                          maxWidth: 90,
                        ),
                      ],
                    ),
                  ),
                  
                  if (isPastEvent)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade800,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Este evento já ocorreu',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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
              context,
              child: Column(
                children: [
                  // Title
                  Text(
                    'SEU QR CODE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Apresente na entrada do evento',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // QR Code with animated container
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2 * _fadeAnimation.value),
                              blurRadius: 20 * _fadeAnimation.value,
                              spreadRadius: 2 * _fadeAnimation.value,
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3 * _fadeAnimation.value),
                            width: 2,
                          ),
                        ),
                        child: QrImageView(
                          data: _dynamicCode,
                          size: qrSize,
                          backgroundColor: Colors.white,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: colorScheme.primary,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Timer indication with progress bar
                  Row(
                    children: [
                      Text(
                        'Código atualiza em:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _remainingSeconds / _intervalSeconds,
                            minHeight: 8,
                            backgroundColor: colorScheme.surfaceVariant,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_remainingSeconds s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Security note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este código é renovado automaticamente por segurança. Mantenha esta tela aberta na entrada do evento.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Purchaser details card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _sectionCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comprador',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${t.purchaserName} ${t.purchaserSurname}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    context,
                    icon: Icons.confirmation_number,
                    title: 'Código do ingresso',
                    value: t.ticketCode,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Número do pedido',
                    value: t.orderId,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    icon: Icons.check_circle,
                    title: 'Status',
                    value: '${t.status[0].toUpperCase()}${t.status.substring(1).toLowerCase()}',
                    valueColor: t.status.toLowerCase() == 'approved' 
                        ? Colors.green.shade700 
                        : Colors.orange.shade700,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconInfoColumn(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
    double maxWidth = 120,
  }) {
    return SizedBox(
      width: maxWidth,
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
    );
  }
}