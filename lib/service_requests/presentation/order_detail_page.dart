import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/date_format.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/infrastructure/api_exception.dart';
import '../../shared/presentation/error_text.dart';
import '../application/service_request_store.dart';
import '../domain/model/service_request.dart';
import 'intervention_page.dart';
import 'orders_page.dart';

/// Screens 04 and 05 · Order detail, acceptance and arrival (US-30, US-33).
/// Reads `GET /service-requests/{id}` and changes the state with accept / reject / start.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.requestId});

  final int requestId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _store = ServiceRequestStore.instance;
  bool _loading = true;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    if (AppState.instance.isOffline) {
      setState(() => _loading = false); // keep the cached copy
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _store.load(widget.requestId);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.danger : null,
      ));
  }

  /// Runs a state change; on a stale state (409) re-reads the request, as the backend guide asks.
  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _snack(successMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.isNetwork ? tr('needsConnection') : errorText(e), isError: true);
      if (e.isConflict || e.isNotFound) await _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(ServiceRequest request) async {
    final reason = await showDialog<String>(context: context, builder: (_) => const _RejectDialog());
    if (reason == null || !mounted) return;
    final navigator = Navigator.of(context);
    await _run(() => _store.reject(request, reason), tr('orderRejectedMsg'));
    if (_store.byId(request.id) == null && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final request = _store.byId(widget.requestId);
      final text = Theme.of(context).textTheme;
      if (request == null) {
        return Scaffold(
          appBar: AppBar(title: Text('${tr('order')} OS-${widget.requestId}')),
          body: Center(
            child: _loading
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error == null ? tr('orderNotFound') : errorText(_error!), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _reload, child: Text(tr('retry'))),
                    ]),
                  ),
          ),
        );
      }
      final queued = _store.isPendingSync(request.id);
      return Scaffold(
        appBar: AppBar(
          title: Text('${tr('order')} ${request.code}'),
          bottom: _loading
              ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
              : null,
        ),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    PriorityBadge(priority: request.priority),
                    const SizedBox(width: 8),
                    queued
                        ? StatusBadge(label: tr('pendingSyncBadge'), color: AppColors.offline)
                        : OrderStatusBadge(status: request.status),
                  ]),
                  const SizedBox(height: 8),
                  Text(request.equipmentName ?? '${tr('equipment')} #${request.equipmentId}', style: text.headlineSmall),
                  Text(serviceTypeLabel(request.type), style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
                ]),
              ),
              const SizedBox(height: 14),
              SectionTitle(tr('orderStatus')),
              const SizedBox(height: 10),
              StatusStepper(status: queued ? ServiceStatus.completed : request.status),
              const SizedBox(height: 14),
              AppCard(
                child: Column(children: [
                  KeyValueRow(icon: Icons.place_outlined, label: tr('site'), value: request.siteName ?? '—'),
                  const SizedBox(height: 14),
                  KeyValueRow(
                      icon: Icons.calendar_today_outlined,
                      label: tr('requestedOn'),
                      value: formatDateTime(request.createdAt),
                      isNumeric: true),
                  if (request.assignedAt != null) ...[
                    const SizedBox(height: 14),
                    KeyValueRow(
                        icon: Icons.assignment_ind_outlined,
                        label: tr('assignedOn'),
                        value: formatDateTime(request.assignedAt),
                        isNumeric: true),
                  ],
                  if (request.startedAt != null) ...[
                    const SizedBox(height: 14),
                    KeyValueRow(
                        icon: Icons.play_circle_outline,
                        label: tr('startedOn'),
                        value: formatDateTime(request.startedAt),
                        isNumeric: true),
                  ],
                  if (request.completedAt != null) ...[
                    const SizedBox(height: 14),
                    KeyValueRow(
                        icon: Icons.check_circle_outline,
                        label: tr('completedOn'),
                        value: formatDateTime(request.completedAt),
                        isNumeric: true),
                  ],
                  if (request.sourceAlertId != null) ...[
                    const SizedBox(height: 14),
                    KeyValueRow(icon: Icons.warning_amber_outlined, label: tr('fromAlert'), value: '#${request.sourceAlertId}'),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration:
                        BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('reportedIssue').toUpperCase(), style: AppTheme.badge(AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Text(request.description.isEmpty ? '—' : request.description),
                    ]),
                  ),
                  if (request.status == ServiceStatus.canceled && request.cancelReason != null) ...[
                    const SizedBox(height: 14),
                    KeyValueRow(icon: Icons.block, label: tr('canceledReason'), value: request.cancelReason!),
                  ],
                ]),
              ),
            ],
          ),
        ),
        bottomNavigationBar: queued
            ? null
            : _ActionBar(
                request: request,
                busy: _busy,
                onAccept: () => _run(() => _store.accept(request), tr('orderAcceptedMsg')),
                onReject: () => _reject(request),
                onStart: () => _run(() => _store.start(request), tr('orderStartedMsg')),
                onIntervention: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => InterventionPage(requestId: request.id))),
              ),
      );
    });
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onReject,
    required this.onStart,
    required this.onIntervention,
  });

  final ServiceRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onStart;
  final VoidCallback onIntervention;

  @override
  Widget build(BuildContext context) {
    Widget? content;
    switch (request.status) {
      case ServiceStatus.pending:
        content = Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
              onPressed: busy ? null : onReject,
              child: Text(tr('reject')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(onPressed: busy ? null : onAccept, child: Text(tr('acceptService'))),
          ),
        ]);
      case ServiceStatus.accepted:
        content = Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('arrivedQuestion'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          FilledButton(onPressed: busy ? null : onStart, child: Text(tr('arrived'))),
        ]);
      case ServiceStatus.inProgress:
        content = FilledButton(onPressed: busy ? null : onIntervention, child: Text(tr('registerIntervention')));
      case ServiceStatus.completed:
      case ServiceStatus.canceled:
        content = null;
    }
    if (content == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(top: false, child: content),
    );
  }
}

/// Asks the reason the backend requires to reject (max 500 characters).
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('rejectReasonTitle')),
      content: TextField(
        controller: _reason,
        autofocus: true,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(hintText: tr('rejectReasonHint')),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _reason.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_reason.text.trim()),
          child: Text(tr('reject')),
        ),
      ],
    );
  }
}
