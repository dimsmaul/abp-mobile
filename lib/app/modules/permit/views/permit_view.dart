import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../controllers/permit_controller.dart';

// Categories supported by the BE. The mobile home shortcuts only expose
// the four "active" ones — sick + permit stay valid for legacy data.
const _kAllCategories = <String>{
  'leave',
  'sick',
  'permit',
  'overtime',
  'reimburse',
  'loan',
};

String _titleForCategory(String c) {
  switch (c) {
    case 'leave':
      return 'Leave Requests';
    case 'sick':
      return 'Sick Requests';
    case 'permit':
      return 'Permit Requests';
    case 'overtime':
      return 'Overtime';
    case 'reimburse':
      return 'Reimbursements';
    case 'loan':
      return 'Loan Requests';
    default:
      return 'Requests';
  }
}

class PermitView extends GetView<PermitController> {
  const PermitView({super.key});

  /// Optional category lock — when this view is opened via the dedicated
  /// home-screen shortcut (e.g. `Get.toNamed('/leave')`), the route
  /// arguments carry the category we should filter to. When opened as the
  /// dashboard tab the arg is absent and the page shows every category.
  String? get _lockedCategory {
    final args = Get.arguments;
    if (args is Map) {
      final c = args['category'];
      if (c is String && _kAllCategories.contains(c)) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final embeddedInDashboard = Get.isRegistered<DashboardController>();
    final locked = _lockedCategory;
    final title = locked == null
        ? 'My Requests'
        : _titleForCategory(locked);
    final showLeaveBalance = locked == null || locked == 'leave';
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppTheme.textPrimary,
        // No back button when shown as a dashboard tab.
        leading: embeddedInDashboard && locked == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Get.back(),
              ),
        automaticallyImplyLeading: !(embeddedInDashboard && locked == null),
      ),
      body: SafeArea(
        child: Obx(() {
          final isInitialLoading =
              controller.isLoading.value && controller.permits.isEmpty;
          final visible = locked == null
              ? controller.permits.toList()
              : controller.permits
                  .where((p) => p['category']?.toString() == locked)
                  .toList();

          if (!isInitialLoading && visible.isEmpty) {
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
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          if (showLeaveBalance)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                if (showLeaveBalance) _LeaveBalanceCard(controller: controller),
                if (showLeaveBalance)
                  Obx(() => controller.leaveBalance.value == null
                      ? const SizedBox.shrink()
                      : const SizedBox(height: 16)),
                if (isInitialLoading)
                  ...List.generate(3, (_) => const _Skeleton())
                else
                  ...visible.map((p) => _PermitCard(permit: p)),
              ],
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPermitSheet(context, locked),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPermitSheet(BuildContext context, String? lockedCategory) {
    if (lockedCategory != null) {
      controller.type.value = lockedCategory;
    }
    Get.bottomSheet(
      _PermitFormSheet(
        controller: controller,
        lockedCategory: lockedCategory,
      ),
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
                    'Remaining leave for $year',
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${remaining.toStringAsFixed(remaining.truncateToDouble() == remaining ? 0 : 1)} of ${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 1)} days',
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
    final singleDate = DateTime.tryParse(permit['date']?.toString() ?? '');
    String rangeStr;
    if (startDate != null && endDate != null) {
      rangeStr =
          '${DateFormat('dd MMM').format(startDate)} – ${DateFormat('dd MMM yyyy').format(endDate)}';
    } else if (singleDate != null) {
      rangeStr = DateFormat('dd MMM yyyy').format(singleDate);
    } else {
      rangeStr = '-';
    }

    final typeIcon = permitTypeIcon(typeStr);
    final typeColor = permitTypeColor(typeStr);

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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              permitTypeLabel(typeStr),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _typeChip(typeStr, typeColor),
                        ],
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
                    'Attachment included',
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

  Widget _typeChip(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
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
            'No requests yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap the + button to submit a new request',
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
  /// When set, the category picker is hidden and the form is locked to
  /// this category. Used by the dedicated home-screen shortcuts so the
  /// user never has to pick a category they already explicitly chose.
  final String? lockedCategory;
  const _PermitFormSheet({
    required this.controller,
    this.lockedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final title = lockedCategory == null
        ? 'New Request'
        : 'New ${_titleForCategory(lockedCategory!).replaceAll(' Requests', '').replaceAll('s', 's')}';
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            if (lockedCategory == null) ...[
              // ── Floating category picker (6 segments). Scrollable when narrow.
              const _FieldLabel('Category'),
              const SizedBox(height: 8),
              _CategoryPicker(controller: controller),
              const SizedBox(height: 20),
            ],

            // Type-specific form fields rebuild as `type` changes.
            Obx(() => _typeFields(context, controller.type.value)),

            const SizedBox(height: 16),
            const _FieldLabel('Description / Reason'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descriptionController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'At least 10 characters — explain briefly',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(Icons.notes, size: 20),
                ),
              ),
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
                      : const Text('Submit',
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

  /// Per-type form. We branch on the active type so each request kind only
  /// shows its own relevant inputs (date range vs single date, hours, amount,
  /// tenor, receipt, etc.).
  Widget _typeFields(BuildContext context, String type) {
    switch (type) {
      case 'leave':
      case 'sick':
      case 'permit':
        return Row(
          children: [
            Expanded(child: _datePicker(context, isStart: true)),
            const SizedBox(width: 12),
            Expanded(child: _datePicker(context, isStart: false)),
          ],
        );
      case 'overtime':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _singleDatePicker(context),
            const SizedBox(height: 16),
            const _FieldLabel('Hours'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.overtimeHoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                hintText: 'e.g. 2.5',
                prefixIcon: Icon(Icons.timer_outlined, size: 20),
              ),
            ),
          ],
        );
      case 'reimburse':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _singleDatePicker(context),
            const SizedBox(height: 16),
            const _FieldLabel('Amount (IDR)'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [_RupiahFormatter()],
              decoration: const InputDecoration(
                hintText: 'Rp 0',
                prefixIcon: Icon(Icons.payments_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Receipt photo'),
            const SizedBox(height: 8),
            _ReceiptPicker(controller: controller),
          ],
        );
      case 'loan':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Amount (IDR)'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [_RupiahFormatter()],
              decoration: const InputDecoration(
                hintText: 'Rp 0',
                prefixIcon: Icon(Icons.payments_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Tenor (months)'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.tenorMonthsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'e.g. 12',
                prefixIcon: Icon(Icons.event_repeat_outlined, size: 20),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _datePicker(BuildContext context, {required bool isStart}) {
    return Obx(() {
      final date =
          isStart ? controller.startDate.value : controller.endDate.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(isStart ? 'Start date' : 'End date'),
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
                date != null ? DateFormat('dd MMM yyyy').format(date) : 'Pick',
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

  Widget _singleDatePicker(BuildContext context) {
    return Obx(() {
      final date = controller.eventDate.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Date'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => controller.selectEventDate(context),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                hintText: '—',
              ),
              child: Text(
                date != null ? DateFormat('dd MMM yyyy').format(date) : 'Pick',
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

class _CategoryPicker extends StatelessWidget {
  final PermitController controller;
  const _CategoryPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.type.value;
      return SizedBox(
        height: 76,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: kPermitTypes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final t = kPermitTypes[i];
            final selected = current == t;
            final color = permitTypeColor(t);
            return InkWell(
              onTap: () => controller.type.value = t,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 84,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.10)
                      : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color : AppTheme.cardBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(permitTypeIcon(t), color: color, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      permitTypeLabel(t),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? color : AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _ReceiptPicker extends StatelessWidget {
  final PermitController controller;
  const _ReceiptPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final img = controller.receiptImage.value;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (img != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  img,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.receipt_long_outlined,
                      color: AppTheme.textHint, size: 32),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickReceiptFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.pickReceiptFromGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

/// Format input as "Rp 1.000.000" while typing. Stores digits only when
/// the parent controller reads .text.
class _RupiahFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = NumberFormat.decimalPattern('id_ID').format(number);
    final out = 'Rp $formatted';
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
