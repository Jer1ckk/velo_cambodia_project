import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/ui/widgets/subscription_status_badge.dart';

import '../../../utils/async_value.dart';
import '../view_model/station_view_model.dart';
import 'stat_chip.dart';

class StationContent extends StatelessWidget {
  const StationContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StationViewModel>();
    final asyncValue = vm.stationDetailValue;

    Widget content;

    switch (asyncValue.state) {
      case AsyncValueState.loading:
        content = const Center(child: CircularProgressIndicator());
        break;

      case AsyncValueState.error:
        content = Center(
          child: Text(
            'error = ${asyncValue.error}',
            style: const TextStyle(color: Colors.red),
          ),
        );
        break;

      case AsyncValueState.success:
        final detail = asyncValue.data!;
        final station = detail.station;

        content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      station.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 4, 16, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  station.street,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  StatChip(
                    icon: Icons.pedal_bike,
                    value: vm.availableBikeCount,
                  ),
                  const SizedBox(width: 10),
                  StatChip(icon: Icons.local_parking, value: vm.emptySlotCount),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFD6E8F7),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 16, color: Color(0xFF5B8DB8)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tip: click on the bike you want to be booked.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: vm.availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = vm.availableSlots[index];
                  final isSelected = vm.selectedSlotNumber == slot.slotNumber;

                  return GestureDetector(
                    onTap: () => vm.selectSlot(slot.slotNumber),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green.withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : const Color(0xFFF4B29D),
                          width: isSelected ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4A261),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'S${slot.slotNumber.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.pedal_bike,
                            color: Color(0xFFF4A261),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              slot.bike.id.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9C6B53),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Row(children: buildRating(slot.bike.rating)),
                          const SizedBox(width: 10),
                          const Text(
                            '5 last review',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 200,
                height: 46,
                child: ElevatedButton(
                  onPressed: vm.selectedSlot == null
                      ? null
                      : () => vm.openBooking(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4A261),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Book The Bike',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Station Info',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [SubscriptionStatusBadge(hasSubscription: vm.hasSubscription)],
      ),
      body: content,
    );
  }
}

List<Widget> buildRating(int rating) {
  return List.generate(
    5,
    (index) => Icon(
      index < rating ? Icons.star : Icons.star_border,
      color: Colors.orange,
      size: 16,
    ),
  );
}
