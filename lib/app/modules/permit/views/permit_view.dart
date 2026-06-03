import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../controllers/permit_controller.dart';

class PermitView extends GetView<PermitController> {
  const PermitView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Permits"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.permits.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchMyPermits();
            await controller.loadLeaveBalance();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _LeaveBalanceCard(controller: controller),
              const SizedBox(height: 16),
              if (controller.permits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined,
                          size: 64, color: AppTheme.textHint),
                      const SizedBox(height: 16),
                      Text("No permit requests yet.",
                          style: TextStyle(
                              color: AppTheme.textHint, fontSize: 16)),
                    ],
                  ),
                )
              else
                ...controller.permits.map((p) => _PermitCard(permit: p)),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPermitSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPermitSheet(BuildContext context) {
    Get.bottomSheet(
      _PermitFormSheet(controller: controller),
      isScrollControlled: true,
    );
  }
}

// ── Leave Balance Card ──
class _LeaveBalanceCard extends StatelessWidget {
  final PermitController controller;
  const _LeaveBalanceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final balance = controller.leaveBalance.value;
      if (balance == null) {
        return const SizedBox.shrink();
      }
      final remaining = (balance['remainingDays'] as num?)?.toDouble() ?? 0;
      final total = (balance['totalDays'] as num?)?.toDouble() ?? 0;
      final year = balance['year']?.toString() ?? '';

      // Traffic-light coloring keyed to remaining cuti so the employee gets
      // a quick at-a-glance signal: > 3 safe, 1-3 caution, 0 blocked.
      Color color;
      if (remaining <= 0) {
        color = Colors.redAccent;
      } else if (remaining <= 3) {
        color = Colors.orangeAccent;
      } else {
        color = Colors.greenAccent.shade400;
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_available, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sisa cuti tahun $year',
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${remaining.toStringAsFixed(remaining.truncateToDouble() == remaining ? 0 : 1)} dari ${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 1)} hari',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Permit Card Widget ──
class _PermitCard extends StatelessWidget {
  final dynamic permit;
  const _PermitCard({required this.permit});

  @override
  Widget build(BuildContext context) {
    final statusStr = permit['status']?.toString() ?? 'pending';
    final typeStr = permit['type']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge(
                permitTypeLabel(typeStr).toUpperCase(),
                AppTheme.primary,
              ),
              _buildBadge(
                permitStatusLabel(statusStr).toUpperCase(),
                permitStatusColor(statusStr),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            permit['description'] ?? '',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: AppTheme.textHint),
              const SizedBox(width: 6),
              Text(
                "${DateFormat('dd MMM').format(DateTime.parse(permit['startDate']))} – ${DateFormat('dd MMM yyyy').format(DateTime.parse(permit['endDate']))}",
                style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Permit Form Bottom Sheet ──
class _PermitFormSheet extends StatelessWidget {
  final PermitController controller;
  const _PermitFormSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text("Ajukan Izin",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            const _FieldLabel('Jenis Izin'),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: controller.type.value,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Pilih jenis',
                    prefixIcon: Icon(Icons.assignment_outlined, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'sick', child: Text('Sakit')),
                    DropdownMenuItem(
                        value: 'leave', child: Text('Cuti Tahunan')),
                    DropdownMenuItem(
                        value: 'permit', child: Text('Izin Khusus')),
                  ],
                  onChanged: (val) {
                    if (val != null) controller.type.value = val;
                  },
                )),

            const SizedBox(height: 16),
            const _FieldLabel('Deskripsi / Alasan'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descriptionController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Minimal 10 karakter, jelaskan alasan singkat',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(Icons.notes, size: 20),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDatePicker(context, isStart: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildDatePicker(context, isStart: false)),
              ],
            ),

            const SizedBox(height: 28),
            Obx(() {
              final isBusy = controller.isSubmitting.value;
              return SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isBusy ? null : controller.submitPermit,
                  child: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Ajukan',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, {required bool isStart}) {
    return Obx(() {
      final date =
          isStart ? controller.startDate.value : controller.endDate.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(isStart ? 'Tanggal Mulai' : 'Tanggal Selesai'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => isStart
                ? controller.selectStartDate(context)
                : controller.selectEndDate(context),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                hintText: '—',
              ),
              child: Text(
                date != null ? DateFormat('dd MMM yyyy').format(date) : 'Pilih',
                style: TextStyle(
                  color: date != null
                      ? AppTheme.textPrimary
                      : AppTheme.textHint,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
