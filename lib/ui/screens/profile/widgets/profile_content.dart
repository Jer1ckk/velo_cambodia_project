import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/ui/utils/date_format.dart';

import '../../../../models/users/user_detail.dart';
import '../../../utils/async_value.dart';
import '../view_model/profile_view_model.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    final mv = context.watch<ProfileViewModel>();
    final AsyncValue<UserDetail> asyncValue = mv.userDetailValue;

    Widget content;

    switch (asyncValue.state) {
      case AsyncValueState.loading:
        content = const Center(child: CircularProgressIndicator());
        break;

      case AsyncValueState.error:
        content = Center(
          child: Text(
            'error = ${asyncValue.error!}',
            style: const TextStyle(color: Colors.red),
          ),
        );
        break;

      case AsyncValueState.success:
        final detail = asyncValue.data!;
        final user = detail.user;
        final subscription = detail.subscription;
        final booking = detail.currentBooking;

        content = SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF7BA35A), width: 3),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: user.imageUrl.isNotEmpty
                      ? NetworkImage(user.imageUrl)
                      : null,
                  child: user.imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 45, color: Colors.grey)
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Subscription',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        title: 'Status',
                        value: mv.hasActiveSubscription
                            ? 'Active ✅'
                            : 'No Pass ❌',
                        valueColor: detail.hasActiveSubscription
                            ? Colors.green
                            : Colors.red,
                      ),
                      const Divider(height: 24),
                      _buildRow(
                        title: 'Type',
                        value: subscription?.durationText ?? '-',
                      ),
                      const Divider(height: 24),
                      _buildRow(
                        title: 'Start Date',
                        value: DateTimeUtils.formatDate(
                          subscription?.startDate,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildRow(
                        title: 'End Date',
                        value: DateTimeUtils.formatDate(subscription?.endDate),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Current Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        title: 'Status',
                        value: detail.hasActiveBooking
                            ? 'Active 🚲'
                            : 'No Booking',
                        valueColor: detail.hasActiveBooking
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const Divider(height: 24),
                      _buildRow(title: 'Bike', value: booking?.bikeId ?? '-'),
                      const Divider(height: 24),
                      _buildRow(
                        title: 'Station',
                        value: booking?.stationId ?? '-',
                      ),
                      const Divider(height: 24),
                      _buildRow(
                        title: 'Slot',
                        value: booking != null
                            ? 'Slot ${booking.slotNumber}'
                            : '-',
                      ),
                      const Divider(height: 24),
                      _buildRow(
                        title: 'Expires',
                        value: DateTimeUtils.formatDateTime(
                          booking?.expiryTime,
                        ),
                        valueColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F4F1),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }

  Widget _buildRow({
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
