import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AppNotification {
  final String id;
  final String type; // 'Expiry' | 'Appointments' | 'Orders' | 'Refills'
  final String title;
  final String description;
  final String time;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.time,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _notifications = [
    const AppNotification(
      id: 'n1',
      type: 'Expiry',
      title: 'Amoxicillin Expiry Warning',
      description: 'Batch #AMX-09 expires in 12 days. Prepare returns.',
      time: '2 hours ago',
    ),
    const AppNotification(
      id: 'n2',
      type: 'Appointments',
      title: 'Consultation Confirmed',
      description: 'Your booking with Dr. Emmanuel Boateng is confirmed for July 15.',
      time: '1 day ago',
    ),
    const AppNotification(
      id: 'n3',
      type: 'Refills',
      title: 'Vitamin C Refill Reminder',
      description: 'Typical refill schedule suggests you might need Vitamin C. Tap to search.',
      time: '2 days ago',
    ),
    const AppNotification(
      id: 'n4',
      type: 'Orders',
      title: 'Supplier Order Shipped',
      description: 'Order #ORD-893 has been shipped by Standard Wholesales.',
      time: '3 days ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Group notifications by type
    final Map<String, List<AppNotification>> grouped = {};
    for (final notif in _notifications) {
      grouped.putIfAbsent(notif.type, () => []).add(notif);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text('Notifications', style: AppTextStyles.subheading),
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Text('All notifications archived.', style: AppTextStyles.body),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: grouped.keys.map((groupTitle) {
                final list = grouped[groupTitle]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        groupTitle.toUpperCase(),
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    ...list.map((notif) {
                      return Padding(
                        key: ValueKey(notif.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey(notif.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              _notifications.removeWhere((item) => item.id == notif.id);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notification archived')),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.statusBad,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.archive_outlined, color: Colors.white),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.hairline),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _getIconForType(notif.type),
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(notif.title, style: AppTextStyles.subheading),
                                      SizedBox(height: 4),
                                      Text(notif.description, style: AppTextStyles.body),
                                      SizedBox(height: 6),
                                      Text(notif.time, style: AppTextStyles.label.copyWith(fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Expiry':
        return Icons.warning_amber_outlined;
      case 'Appointments':
        return Icons.event_available_outlined;
      case 'Orders':
        return Icons.local_shipping_outlined;
      case 'Refills':
        return Icons.autorenew;
      default:
        return Icons.notifications_none;
    }
  }
}
