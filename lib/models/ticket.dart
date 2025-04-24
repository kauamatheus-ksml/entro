// File: lib/models/ticket.dart

import 'package:flutter/material.dart';

class Ticket {
  final int id;
  final String orderId;
  final String ticketCode;
  final String purchaserName;
  final String purchaserSurname;
  final double valorTotal;
  final int quantidadeTotal;
  final String status;
  final DateTime createdAt;
  final int eventoId;
  final bool validado;
  final String eventoNome;
  final String eventoLocal;
  final DateTime eventoData;
  final TimeOfDay eventoHorario;
  final String eventoLogo;
  final String? tipoIngresso;

  Ticket({
    required this.id,
    required this.orderId,
    required this.ticketCode,
    required this.purchaserName,
    required this.purchaserSurname,
    required this.valorTotal,
    required this.quantidadeTotal,
    required this.status,
    required this.createdAt,
    required this.eventoId,
    required this.validado,
    required this.eventoNome,
    required this.eventoLocal,
    required this.eventoData,
    required this.eventoHorario,
    required this.eventoLogo,
    this.tipoIngresso,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Monta DateTime a partir de data + hora
    final dataStr = json['evento_data'] as String? ?? '';
    final horaStr = json['evento_horario'] as String? ?? '00:00';
    final dt = DateTime.tryParse('$dataStr $horaStr') ?? DateTime.now();

    return Ticket(
      id: json['id'] as int? ?? 0,
      orderId: json['order_id'] as String? ?? '',
      ticketCode: json['ticket_code'] as String? ?? '',
      purchaserName: json['comprador_nome'] as String? ?? '',
      purchaserSurname: json['comprador_sobrenome'] as String? ?? '',
      valorTotal: double.tryParse(json['valor_total']?.toString() ?? '') ?? 0.0,
      quantidadeTotal: json['quantidade_total'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      eventoId: json['evento_id'] as int? ?? 0,
      validado: (json['ingresso_validado']?.toString() ?? '0') == '1',
      eventoNome: json['evento_nome'] as String? ?? '',
      eventoLocal: json['evento_local'] as String? ?? '',
      eventoData: dt,
      eventoHorario: TimeOfDay(hour: dt.hour, minute: dt.minute),
      eventoLogo: json['evento_logo'] as String? ?? '',
      tipoIngresso: json['tipo_ingresso'] as String?,
    );
  }

  /// Converte este objeto para JSON (útil para cache offline).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'ticket_code': ticketCode,
      'comprador_nome': purchaserName,
      'comprador_sobrenome': purchaserSurname,
      'valor_total': valorTotal,
      'quantidade_total': quantidadeTotal,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'evento_id': eventoId,
      'ingresso_validado': validado ? 1 : 0,
      'evento_nome': eventoNome,
      'evento_local': eventoLocal,
      'evento_data': eventoData.toIso8601String().split('T').first,
      'evento_horario':
          '${eventoHorario.hour.toString().padLeft(2, '0')}:${eventoHorario.minute.toString().padLeft(2, '0')}',
      'evento_logo': eventoLogo,
      if (tipoIngresso != null) 'tipo_ingresso': tipoIngresso,
    };
  }
}
