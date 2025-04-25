import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
import '../widgets/ticket_card.dart';
import 'ticket_details_screen.dart';
import 'profile_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final ApiService _api = ApiService();
  late Future<List<Ticket>> _futureTickets;
  bool _showUpcoming = true; // Começa mostrando eventos próximos
  bool _showDebug = false; // Toggle for debugging image URLs

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    setState(() {
      _futureTickets = _api.getTickets();
    });
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  // Debug widget to help diagnose image issues
  Widget _debugImages(List<Ticket> tickets) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.amber.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("DEBUG: Image URLs", style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => setState(() => _showDebug = false),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Evento: ${ticket.eventoNome}"),
                    Text("URL: ${ticket.eventoLogo}"),
                    SizedBox(height: 6),
                    ticket.eventoLogo.isNotEmpty 
                        ? Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ticket.eventoLogo,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.red.withOpacity(0.3),
                                      child: Icon(Icons.error, color: Colors.red),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.withOpacity(0.3),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / 
                                                loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Status: Tentando carregar...",
                                  style: TextStyle(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text("No image URL provided", style: TextStyle(color: Colors.red)),
                    Divider(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Ingressos'),
        centerTitle: true,
        actions: [
          // Debug button
          IconButton(
            icon: Icon(Icons.bug_report),
            tooltip: 'Debug Images',
            onPressed: () => setState(() => _showDebug = !_showDebug),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loadTickets,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Meu Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab buttons
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              children: [
                // Próximos button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showUpcoming = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showUpcoming ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: _showUpcoming
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Próximos',
                        style: TextStyle(
                          color: _showUpcoming
                              ? colorScheme.primary
                              : Colors.grey.shade700,
                          fontWeight: _showUpcoming
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // Anteriores button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showUpcoming = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showUpcoming ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: !_showUpcoming
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Anteriores',
                        style: TextStyle(
                          color: !_showUpcoming
                              ? colorScheme.primary
                              : Colors.grey.shade700,
                          fontWeight: !_showUpcoming
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: FutureBuilder<List<Ticket>>(
              future: _futureTickets,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Erro: ${snap.error}'));
                }
                
                final allTickets = snap.data!;
                if (allTickets.isEmpty) {
                  return const Center(child: Text('Nenhum ingresso encontrado.'));
                }

                // Show debug view if enabled
                if (_showDebug) {
                  return _debugImages(allTickets);
                }

                // Nova lógica: 
                // - "Anteriores" são eventos que já aconteceram OU que já foram validados
                // - "Próximos" são eventos futuros que ainda não foram validados
                final now = DateTime.now();
                
                final upcomingTickets = allTickets
                    .where((t) => 
                        !t.validado && // Não validado E
                        (t.eventoData.isAfter(now) || // Futuro OU
                         (t.eventoData.year == now.year && // Hoje
                          t.eventoData.month == now.month && 
                          t.eventoData.day == now.day))
                    )
                    .toList();
                    
                final pastTickets = allTickets
                    .where((t) => 
                        t.validado || // Validado OU
                        t.eventoData.isBefore(now) // Passado
                    )
                    .toList();

                // Mostra próximos ou anteriores baseado na seleção
                final tickets = _showUpcoming ? upcomingTickets : pastTickets;
                
                if (tickets.isEmpty) {
                  return Center(
                    child: Text(
                      _showUpcoming
                          ? 'Nenhum ingresso futuro pendente.'
                          : 'Nenhum ingresso anterior ou validado.'
                    ),
                  );
                }

                // Agrupa por mês do evento em Português
                final Map<String, List<Ticket>> grouped = {};
                for (var t in tickets) {
                  final key = DateFormat.yMMMM('pt_BR').format(t.eventoData);
                  grouped.putIfAbsent(key, () => []).add(t);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadTickets();
                    // wait a moment so spinner shows
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              entry.key[0].toUpperCase() + entry.key.substring(1),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          for (var ticket in entry.value)
                            TicketCard(
                              ticket: ticket,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TicketDetailsScreen(
                                      orderId: ticket.orderId,
                                      ticketCode: ticket.ticketCode,
                                    ),
                                  ),
                                ).then((_) {
                                  // Reload tickets when returning from details
                                  // This ensures validation status is updated
                                  _loadTickets();
                                });
                              },
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}