// File: lib/widgets/ticket_card.dart

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

    // Se houver tipo, pega ícone; senão, padrão
    final typeIcon = ticket.tipoIngresso != null
        ? _iconForType(ticket.tipoIngresso!)
        : Icons.confirmation_number;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1) Miniatura do evento
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ticket.eventoLogo.isNotEmpty
                  ? Image.network(
                      ticket.eventoLogo,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.event, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.event, color: Colors.grey),
                    ),
            ),

            const SizedBox(width: 12),

            // 2) Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linha do pedido + tipo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pedido #${ticket.orderId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ticket.tipoIngresso != null) ...[
                        Row(
                          children: [
                            Icon(typeIcon,
                                color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              ticket.tipoIngresso!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Nome do evento
                  Text(
                    ticket.eventoNome,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Local
                  Row(
                    children: [
                      const Icon(Icons.place,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ticket.eventoLocal,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Data / dia / hora
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$diaSemana, $data às $hora',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3) seta de navegação
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
