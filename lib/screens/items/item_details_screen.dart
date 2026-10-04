import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/lost_found_item.dart';
import '../../services/item_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/campus_app_bar.dart';

class ItemDetailsScreen extends StatefulWidget {
  final LostFoundItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final ItemService _itemService = ItemService();

  late String currentStatus;

  bool isUpdating = false;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.item.status;
  }

  bool get isOwner {
    final user = FirebaseAuth.instance.currentUser;

    return user != null && user.uid == widget.item.createdBy;
  }

  bool get isLost => widget.item.type == 'lost';

  Color get typeColor => isLost ? AppTheme.lostColor : AppTheme.foundColor;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _capitalise(String value) {
    if (value.isEmpty) return value;

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      isUpdating = true;
    });

    try {
      await _itemService.updateItemStatus(
        itemId: widget.item.id,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        currentStatus = status;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${_capitalise(status)}.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Report?'),
          content: const Text('This report will be permanently removed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isDeleting = true;
    });

    try {
      await _itemService.deleteItem(itemId: widget.item.id);

      if (!mounted) return;

      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CampusAppBar(title: 'Item Details'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLost ? 'LOST ITEM' : 'FOUND ITEM',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.item.category,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _InfoCard(
                title: 'Status',
                value: _capitalise(currentStatus),
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Date',
                value: _formatDate(widget.item.eventDate),
                icon: Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Description',
                value: widget.item.description,
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Location',
                value:
                    widget.item.latitude != null &&
                        widget.item.longitude != null
                    ? 'Latitude: ${widget.item.latitude!.toStringAsFixed(6)}\nLongitude: ${widget.item.longitude!.toStringAsFixed(6)}'
                    : 'No GPS location attached.',
                icon: Icons.location_on_outlined,
              ),
              if (isOwner) ...[
                const SizedBox(height: 26),
                const Text(
                  'Owner Actions',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: currentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Report Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'matched', child: Text('Matched')),
                    DropdownMenuItem(
                      value: 'returned',
                      child: Text('Returned'),
                    ),
                  ],
                  onChanged: isUpdating
                      ? null
                      : (value) {
                          if (value != null) {
                            _updateStatus(value);
                          }
                        },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: isDeleting ? null : _deleteItem,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(isDeleting ? 'Deleting...' : 'Delete Report'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
