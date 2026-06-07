import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/event_item.dart';
import '../../services/event_service.dart';

class EventCheckoutPage extends StatefulWidget {
  final EventItem event;
  final int tickets;
  final String attendeeThixId;
  final String attendeeName;
  final String? attendeeEmail;
  final String? attendeePhone;
  final String? note;

  const EventCheckoutPage({
    super.key,
    required this.event,
    required this.tickets,
    required this.attendeeThixId,
    required this.attendeeName,
    this.attendeeEmail,
    this.attendeePhone,
    this.note,
  });

  @override
  State<EventCheckoutPage> createState() => _EventCheckoutPageState();
}

class _EventCheckoutPageState extends State<EventCheckoutPage> {
  late final EventService _eventService = EventService(Supabase.instance.client);

  bool _loading = false;

  double get subtotal => widget.event.price * widget.tickets;
  double get total => subtotal;

  Future<void> _completeCheckout() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final registration = await _eventService.createRegistration(
        userId: user.id,
        eventId: widget.event.id,
        metadata: {
          'tickets': widget.tickets,
          'attendee_thix_id': widget.attendeeThixId,
          'attendee_name': widget.attendeeName,
          'attendee_email': widget.attendeeEmail,
          'attendee_phone': widget.attendeePhone,
          'note': widget.note,
          'amount_paid': total,
        },
      );

      if (registration != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement validé avec succès !')),
        );

        context.go('/events/${widget.event.id}/ticket/${registration.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildPriceRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(event.location),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text('Résumé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPriceRow('Nombre de billets', widget.tickets.toString()),
                      _buildPriceRow('Sous-total', '${subtotal.toStringAsFixed(2)} USD'),
                      const Divider(),
                      _buildPriceRow('Total', '${total.toStringAsFixed(2)} USD', bold: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paiement THIX', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Paiement simulé pour le moment.\nIntégrez Stripe / Mobile Money plus tard.'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _completeCheckout,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.payment),
                  label: const Text('Confirmer et payer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
