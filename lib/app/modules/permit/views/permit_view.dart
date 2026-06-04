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
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Pengajuan Saya'),
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final isInitialLoading =
              controller.isLoading.value && controller.permits.isEmpty;

          if (!isInitialLoading && controller.permits.isEmpty) {
            return LayoutBuilder(
              builder: (ctx, bc) => RefreshIndicator(
                onRefresh: () async {
                  await controller.fetchMyPermits();
                  await controller.loadLeaveBalance();
                },
                color: AppTheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: bc.maxHeight),
                    // IntrinsicHeight gives the inner Column a bounded
                    // vertical constraint inside the scroll view so the
                    // Expanded child below can lay out instead of throwing
                    // "RenderFlex … unbounded height" from
                    // SingleChildScrollView's infinite axis.
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: _LeaveBalanceCard(controller: controller),
                          ),
                          const Expanded(child: Center(child: _Empty())),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.fetchMyPermits();
              await controller.loadLeaveBalance();
            },
            color: AppTheme.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                _LeaveBalanceCard(controller: controller),
                Obx(() => controller.leaveBalance.value == null
                    ? const SizedBox.shrink()
                    : const SizedBox(height: 16)),
                if (isInitialLoading)
                  ...List.generate(3, (_) => const _Skeleton())
                else
                  ...controller.permits.map((p) => _PermitCard(permit: p)),
              ],
            ),
          );
        }),
      ),
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
    final desc = permit['description']?.toString() ?? '';
    final attachmentUrl = permit['attachmentUrl']?.toString();

    final startDate = DateTime.tryParse(permit['startDate']?.toString() ?? '');
    final endDate = DateTime.tryParse(permit['endDate']?.toString() ?? '');
    final rangeStr = (startDate != null && endDate != null)
        ? '${DateFormat('dd MMM').format(startDate)} – ${DateFormat('dd MMM yyyy').format(endDate)}'
        : '-';

    final typeIcon = _typeIcon(typeStr);
    final typeColor = _typeColor(typeStr);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permitTypeLabel(typeStr),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppTheme.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              rangeStr,
                              style: const TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(statusStr),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
            if (attachmentUrl != null && attachmentUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.attach_file,
                      size: 12, color: AppTheme.textHint),
                  SizedBox(width: 4),
                  Text(
                    'Lampiran terlampir',
                    style: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'sick':
        return Icons.favorite_outline;
      case 'leave':
        return Icons.beach_access_outlined;
      case 'permit':
        return Icons.event_note_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'sick':
        return AppTheme.danger;
      case 'leave':
        return AppTheme.primary;
      case 'permit':
        return AppTheme.warning;
      default:
        return AppTheme.textHint;
    }
  }

  Widget _statusBadge(String status) {
    final color = permitStatusColor(status);
    final label = permitStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Empty + Skeleton ──
class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: AppTheme.primary, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada pengajuan',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ketuk tombol + untuk mengajukan izin baru',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 110,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 170,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
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
