import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'api_service.dart';
import '../models/ticket.dart';

class TicketRepository {
  final ApiService _api = ApiService();
  final Box<Ticket> _box = Hive.box<Ticket>('tickets');
  final Box<Map> _pendBox = Hive.box<Map>('pendingValidations');

  Future<bool> _online() async {
    final c = await Connectivity().checkConnectivity();
    return c != ConnectivityResult.none;
  }

  /// Retorna tickets; se online, busca API e atualiza cache; senão, devolve cache
  Future<List<Ticket>> fetchTickets() async {
    if (await _online()) {
      final list = await _api.getTickets();
      // limpa e regrava
      await _box.clear();
      for (var t in list) {
        await _box.put(t.orderId, t);
      }
      // tenta sincronizar validações pendentes
      await _syncValidations();
      return list;
    } else {
      return _box.values.toList();
    }
  }

  /// Marca localmente como validado; se online, imediatamente envia; senão pendura
  Future<void> validateTicket(String orderId) async {
    final t = _box.get(orderId);
    if (t == null) throw 'Ingresso não encontrado localmente';
    t.validado = true;
    await t.save();

    if (await _online()) {
      await _api.validateTicketOnServer(t.id); // você deve implementar esse endpoint
    } else {
      // grava pendência
      _pendBox.put(orderId, {'id': t.id});
    }
  }

  /// Envia todas pendências
  Future<void> _syncValidations() async {
    if (!(await _online())) return;
    for (var key in _pendBox.keys) {
      final map = _pendBox.get(key);
      try {
        await _api.validateTicketOnServer(map!['id']);
        _pendBox.delete(key);
      } catch (_) { /* mantém pendência*/ }
    }
  }
}
