import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/async_value.dart';
import '../view_model/booking_view_model.dart';
import 'booking_banner.dart';

class BookingBikeContent extends StatelessWidget {
  const BookingBikeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingBikeViewModel>();
    final asyncValue = vm.bookingValue;

    Widget content;

    switch (asyncValue.state) {
      case AsyncValueState.loading:
        content = const Center(child: CircularProgressIndicator());
        break;

      case AsyncValueState.error:
        content = Center(
          child: Text(
            'Error: ${asyncValue.error}',
            style: const TextStyle(color: Colors.red),
          ),
        );
        break;

      case AsyncValueState.success:
        content = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.hasActiveBooking)
                const BookingBanner(
                  backgroundColor: Color(0xFFF9D4D0),
                  borderColor: Color(0xFFE36D62),
                  icon: Icons.warning,
                  iconColor: Color(0xFFC0392B),
                  text: 'You already have an active booking.',
                  textColor: Color(0xFFC0392B),
                )
              else if (vm.hasActivePass)
                const BookingBanner(
                  backgroundColor: Color(0xFFD6EBC8),
                  borderColor: Color(0xFF8FBC73),
                  icon: Icons.confirmation_number,
                  iconColor: Color(0xFF5E8E3E),
                  text: 'Your pass is active. Booking is allowed.',
                  textColor: Color(0xFF447027),
                )
              else
                const BookingBanner(
                  backgroundColor: Color(0xFFF9D4D0),
                  borderColor: Color(0xFFE36D62),
                  icon: Icons.error,
                  iconColor: Color(0xFFC0392B),
                  text: 'You must have an active pass to book.',
                  textColor: Color(0xFFC0392B),
                ),

              const SizedBox(height: 20),

              const Text(
                'Booking Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              const Row(
                children: [
                  Icon(Icons.access_time, color: Color(0xFF82B366)),
                  SizedBox(width: 10),
                  Text(
                    'Pickup Deadline: 60 mins',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              if (!vm.hasActiveBooking && vm.hasActivePass)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF0D1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF8FBC73)),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: vm.agreeBooking,
                        onChanged: (v) => vm.toggleAgree(v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Covered by your active pass',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: vm.canConfirm
                      ? () => vm.confirmBooking(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: vm.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Confirm Booking',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Booking Bike'),
      ),
      body: content,
    );
  }
}
