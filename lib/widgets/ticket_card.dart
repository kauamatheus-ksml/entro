import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({
    Key? key,
    required this.ticket,
    required this.onTap,
  }) : super(key: key);

  /// Mapea tipos para ícones
  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'vip':
        return Icons.star;
      case 'premium':
        return Icons.local_activity;
      case 'geral':
      case 'general':
        return Icons.event_seat;
      default:
        return Icons.confirmation_number;
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaSemana = DateFormat.EEEE('pt_BR').format(ticket.eventoData);
    final data = DateFormat('dd/MM/yyyy', 'pt_BR').format(ticket.eventoData);
    final hora = ticket.eventoHorario.format(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Se houver tipo, pega ícone; senão, padrão
    final typeIcon = ticket.tipoIngresso != null
        ? _iconForType(ticket.tipoIngresso!)
        : Icons.confirmation_number;
    
    // Determina se a data já passou
    final bool isPastEvent = ticket.eventoData.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isPastEvent ? Colors.grey.shade300 : Colors.transparent,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 1) Miniatura do evento com sobreposição de status
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ticket.eventoLogo.isNotEmpty
                                ? Image.network(
                                    ticket.eventoLogo,
                                    width: 70,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 70,
                                      height: 90,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.event, color: Colors.grey, size: 32),
                                    ),
                                  )
                                : Container(
                                    width: 70,
                                    height: 90,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.event, color: Colors.grey, size: 32),
                                  ),
                            ),
                          
                          // Status overlay if past event
                          if (isPastEvent)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'PASSADO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                          // Add a badge for ticket type if available
                          if (ticket.tipoIngresso != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                ),
                                child: Icon(
                                  typeIcon,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // 2) Conteúdo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome do evento
                            Text(
                              ticket.eventoNome,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isPastEvent ? Colors.grey.shade700 : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),

                            const SizedBox(height: 8),

                            // Local
                            Row(
                              children: [
                                Icon(
                                  Icons.place,
                                  size: 16,
                                  color: isPastEvent ? Colors.grey.shade500 : colorScheme.primary.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    ticket.eventoLocal,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isPastEvent ? Colors.grey.shade600 : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Data / dia / hora
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: isPastEvent ? Colors.grey.shade500 : colorScheme.primary.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$diaSemana, $data',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isPastEvent ? Colors.grey.shade600 : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 6),
                            
                            // Hora com ícone de relógio
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16, 
                                  color: isPastEvent ? Colors.grey.shade500 : colorScheme.primary.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hora,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isPastEvent ? Colors.grey.shade600 : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                // ID do pedido como badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPastEvent ? Colors.grey.shade200 : colorScheme.primaryContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '#${ticket.orderId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isPastEvent ? Colors.grey.shade700 : colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Animated side accent
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isPastEvent ? Colors.grey.shade400 : colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                
                // Corner decoration
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isPastEvent ? Colors.grey.shade300 : colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: isPastEvent ? Colors.grey.shade700 : colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}