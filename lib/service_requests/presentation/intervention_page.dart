import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/infrastructure/uuid.dart';
import '../../shared/presentation/error_text.dart';
import '../application/service_request_store.dart';
import '../domain/model/intervention_report.dart';

/// Screen 07 · Register intervention, also offline (US-31). Sends `POST /interventions`;
/// without connection the report is stored on the phone and replayed later.
class InterventionPage extends StatefulWidget {
  const InterventionPage({super.key, required this.requestId});

  final int requestId;

  @override
  State<InterventionPage> createState() => _InterventionPageState();
}

class _InterventionPageState extends State<InterventionPage> {
  final _diagnosis = TextEditingController();
  final _otherActions = TextEditingController();
  final _partInput = TextEditingController();

  /// Quick picks; the selected ones plus the free text become `actions_taken`.
  final Map<String, bool> _actions = {
    'actionCleanCondenser': false,
    'actionCalibrateThermostat': false,
    'actionRechargeRefrigerant': false,
    'actionReplaceFilter': false,
    'actionCheckDoorSeals': false,
  };
  final List<String> _parts = [];

  /// Generated once per intervention and kept across retries (idempotency key).
  final String _clientGeneratedId = uuidV4();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _diagnosis.dispose();
    _otherActions.dispose();
    _partInput.dispose();
    super.dispose();
  }

  void _addPart() {
    final part = _partInput.text.trim();
    if (part.isEmpty || _parts.length >= 50) return;
    setState(() {
      _parts.add(part.length > 100 ? part.substring(0, 100) : part);
      _partInput.clear();
    });
  }

  String _actionsTaken() {
    final picked = _actions.entries.where((e) => e.value).map((e) => tr(e.key)).toList();
    final other = _otherActions.text.trim();
    if (other.isNotEmpty) picked.add(other);
    return picked.join('; ');
  }

  Future<void> _finish() async {
    final diagnosis = _diagnosis.text.trim();
    final actions = _actionsTaken();
    if (diagnosis.isEmpty) {
      setState(() => _error = tr('diagnosisRequired'));
      return;
    }
    if (actions.isEmpty) {
      setState(() => _error = tr('actionsRequired'));
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = await ServiceRequestStore.instance.submitIntervention(InterventionReport(
        clientGeneratedId: _clientGeneratedId,
        serviceRequestId: widget.requestId,
        diagnosis: diagnosis.length > 2000 ? diagnosis.substring(0, 2000) : diagnosis,
        actionsTaken: actions.length > 2000 ? actions.substring(0, 2000) : actions,
        spareParts: List.of(_parts),
        completedAt: DateTime.now(),
      ));
      if (!mounted) return;
      final sent = result == SubmitResult.sent;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: sent ? AppColors.success : AppColors.offline,
        content: Text(sent ? tr('sentOnline') : tr('savedOffline')),
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final store = ServiceRequestStore.instance;
      final request = store.byId(widget.requestId);
      final text = Theme.of(context).textTheme;
      return Scaffold(
        appBar: AppBar(title: Text(tr('registerIntervention'))),
        body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
          if (store.isOfflineNow || AppState.instance.isOffline) ...[
            SyncBanner(message: tr('offlineBanner')),
            const SizedBox(height: 12),
          ],
          Row(children: [
            Expanded(
              child: Text(
                '${request?.code ?? 'OS-${widget.requestId}'} · ${request?.equipmentName ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (request != null) OrderStatusBadge(status: request.status),
          ]),
          const SizedBox(height: 16),
          Text(tr('diagnosis'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _diagnosis,
            enabled: !_sending,
            maxLines: 3,
            maxLength: 2000,
            decoration: InputDecoration(hintText: tr('diagnosisHint')),
          ),
          const SizedBox(height: 8),
          Text(tr('actionsDone'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final entry in _actions.entries)
              Chip2(
                label: tr(entry.key),
                isSelected: entry.value,
                showCheck: true,
                onTap: () => setState(() => _actions[entry.key] = !entry.value),
              ),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _otherActions,
            enabled: !_sending,
            maxLines: 2,
            decoration: InputDecoration(hintText: tr('otherActionsHint')),
          ),
          const SizedBox(height: 16),
          Text(tr('spareParts'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final part in _parts) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const IconCircle(icon: Icons.inventory_2_outlined, color: AppColors.primary, size: 36),
                const SizedBox(width: 12),
                Expanded(child: Text(part, style: const TextStyle(fontWeight: FontWeight.w600))),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _sending ? null : () => setState(() => _parts.remove(part)),
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ],
          Row(children: [
            Expanded(
              child: TextField(
                controller: _partInput,
                enabled: !_sending,
                decoration: InputDecoration(hintText: tr('partHint')),
                onSubmitted: (_) => _addPart(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(onPressed: _sending ? null : _addPart, icon: const Icon(Icons.add)),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
        ]),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration:
              const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FilledButton(
                onPressed: _sending ? null : _finish,
                child: _sending
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(tr('finishService')),
              ),
              const SizedBox(height: 8),
              Text(
                '${tr('localId')} ${_clientGeneratedId.substring(0, 8).toUpperCase()} · ${tr('localIdNote')}',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(fontFeatures: AppTheme.numeric().fontFeatures),
              ),
            ]),
          ),
        ),
      );
    });
  }
}
