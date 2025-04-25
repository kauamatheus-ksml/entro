// lib/screens/tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';
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
  int _currentIndex = 0;

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
  
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }
  
  void _handleNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0: // Tickets
        // Já estamos na tela de tickets
        break;
      case 1: // Perfil
        _openProfile();
        break;
      case 2: // Atualizar
        _loadTickets();
        break;
      case 3: // Logout
        _logout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryBlue = const Color(0xFF012F6D);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Ingressos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryBlue,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab buttons
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _showUpcoming ? primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Próximos',
                        style: TextStyle(
                          color: _showUpcoming ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // Passados button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showUpcoming = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: !_showUpcoming ? primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Passados',
                        style: TextStyle(
                          color: !_showUpcoming ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Espaço para a bottom navigation bar
                  itemCount: grouped.entries.length,
                  itemBuilder: (context, indexGroup) {
                    final entry = grouped.entries.elementAt(indexGroup);
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
                          _buildTicketItem(context, ticket, !_showUpcoming, primaryBlue),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryBlue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _currentIndex,
        onTap: _handleNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.refresh),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildTicketItem(BuildContext context, Ticket ticket, bool isPast, Color primaryColor) {
    final dateFormatter = DateFormat('EEEE, dd/MM/yyyy', 'pt_BR');
    String formattedDate = dateFormatter.format(ticket.eventoData);
    formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);
    
    // Formatação da hora no formato 24h
    final timeStr = '${ticket.eventoHorario.hour.toString().padLeft(2, '0')}:${ticket.eventoHorario.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
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
            _loadTickets();
          });
        },
        child: Row(
          children: [
            // Lado esquerdo - Logo do evento
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: isPast ? Colors.grey.shade600 : primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: ticket.eventoLogo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/ticketsyhnklogo.png',
                        image: ticket.eventoLogo,
                        fit: BoxFit.cover,
                        width: 110,
                        height: 110,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Image.asset(
                              'assets/ticketsyhnklogo.png',
                              width: 80,
                              height: 80,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Image.asset(
                        'assets/ticketsyhnklogo.png',
                        width: 80,
                        height: 80,
                        color: Colors.white,
                      ),
                    ),
            ),
            
            // Lado direito - Detalhes do evento
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.eventoNome,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    
                    // Local com ícone
                    Row(
                      children: [
                        Icon(Icons.location_on, color: primaryColor, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ticket.eventoLocal,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Data com ícone
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: primaryColor, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Hora e quantidade de ingressos
                    Row(
                      children: [
                        Icon(Icons.access_time, color: primaryColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Icon(Icons.confirmation_number, color: primaryColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${ticket.quantidadeTotal} Ingresso${ticket.quantidadeTotal > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Número do ingresso e seta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '#${ticket.orderId}',
                          style: TextStyle(
                            fontSize: 14, 
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, color: primaryColor, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}