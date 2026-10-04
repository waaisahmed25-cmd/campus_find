import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/lost_found_item.dart';
import '../../services/item_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/campus_app_bar.dart';
import 'item_details_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final ItemService _itemService = ItemService();
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';
  String selectedType = 'all';
  String selectedStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<LostFoundItem> _filterItems(List<LostFoundItem> items) {
    return items.where((item) {
      final query = searchQuery.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      final matchesType = selectedType == 'all' || item.type == selectedType;

      final matchesStatus =
          selectedStatus == 'all' || item.status == selectedStatus;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('You must be logged in to view your reports.'),
        ),
      );
    }

    return Scaffold(
      appBar: const CampusAppBar(title: 'My Reports'),
      body: StreamBuilder<List<LostFoundItem>>(
        stream: _itemService.getItemsByUser(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load your reports.'));
          }

          final items = snapshot.data ?? [];
          final filteredItems = _filterItems(items);

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Reports',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Manage your lost and found reports.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search your reports',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All Types',
                              selected: selectedType == 'all',
                              color: AppTheme.primary,
                              onTap: () {
                                setState(() {
                                  selectedType = 'all';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Lost',
                              selected: selectedType == 'lost',
                              color: AppTheme.lostColor,
                              onTap: () {
                                setState(() {
                                  selectedType = 'lost';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Found',
                              selected: selectedType == 'found',
                              color: AppTheme.foundColor,
                              onTap: () {
                                setState(() {
                                  selectedType = 'found';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All Status',
                              selected: selectedStatus == 'all',
                              color: AppTheme.primary,
                              onTap: () {
                                setState(() {
                                  selectedStatus = 'all';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Active',
                              selected: selectedStatus == 'active',
                              color: AppTheme.primary,
                              onTap: () {
                                setState(() {
                                  selectedStatus = 'active';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Matched',
                              selected: selectedStatus == 'matched',
                              color: Colors.orange,
                              onTap: () {
                                setState(() {
                                  selectedStatus = 'matched';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Returned',
                              selected: selectedStatus == 'returned',
                              color: AppTheme.foundColor,
                              onTap: () {
                                setState(() {
                                  selectedStatus = 'returned';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredItems.isEmpty
                      ? const Center(child: Text('No reports found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isLost = item.type == 'lost';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      (isLost
                                              ? AppTheme.lostColor
                                              : AppTheme.foundColor)
                                          .withValues(alpha: 0.10),
                                  child: Icon(
                                    isLost
                                        ? Icons.search_rounded
                                        : Icons.inventory_2_outlined,
                                    color: isLost
                                        ? AppTheme.lostColor
                                        : AppTheme.foundColor,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.category}\n${_formatDate(item.eventDate)} • ${item.status}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ItemDetailsScreen(item: item),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.10),
      backgroundColor: Colors.white,
    );
  }
}
