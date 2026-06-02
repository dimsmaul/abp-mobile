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
        if (controller.permits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined,
                    size: 64, color: AppTheme.textHint),
                const SizedBox(height: 16),
                Text("No permit requests yet.",
                    style: TextStyle(color: AppTheme.textHint, fontSize: 16)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchMyPermits,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.permits.length,
            itemBuilder: (context, index) =>
                _PermitCard(permit: controller.permits[index]),
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
            Text("Request Permit",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: controller.type.value,
                  dropdownColor: AppTheme.cardBg,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: "Permit Type"),
                  items: const [
                    DropdownMenuItem(value: 'sick', child: Text("Sick Leave")),
                    DropdownMenuItem(
                        value: 'leave', child: Text("Annual Leave")),
                    DropdownMenuItem(
                        value: 'permit', child: Text("Special Permit")),
                  ],
                  onChanged: (val) => controller.type.value = val!,
                )),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration:
                  const InputDecoration(labelText: "Description / Reason"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDatePicker(context, isStart: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildDatePicker(context, isStart: false)),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: controller.submitPermit,
              child: const Text("Submit Request"),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, {required bool isStart}) {
    return Obx(() {
      final date = isStart ? controller.startDate.value : controller.endDate.value;
      return InkWell(
        onTap: () => isStart
            ? controller.selectStartDate(context)
            : controller.selectEndDate(context),
        child: InputDecorator(
          decoration:
              InputDecoration(labelText: isStart ? "Start Date" : "End Date"),
          child: Text(
            date != null ? DateFormat('dd/MM/yyyy').format(date) : "Select",
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      );
    });
  }
}
