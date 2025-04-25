import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
import '../widgets/ticket_card.dart';
import 'ticket_details_screen.dart';
import 'profile_screen.dart'; // Add this import for the profile screen

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final ApiService _api = ApiService();
  late Future<List<Ticket>> _futureTickets;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    setState(() {
      _futureTickets = _api.getTickets(); // Fixed the typo here
    });
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Ingressos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loadTickets,
          ),
          // Add profile icon between refresh and logout
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Meu Perfil',
            onPressed: () {
              // Navigate to ProfileScreen
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
      body: FutureBuilder<List<Ticket>>(
        future: _futureTickets,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          final tickets = snap.data!;
          if (tickets.isEmpty) {
            return const Center(child: Text('Nenhum ingresso encontrado.'));
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
                          );
                        },
                      ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}