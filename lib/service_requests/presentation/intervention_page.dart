import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../domain/service_order.dart';

/// Screen 07 · Register intervention, also offline (US-31).
class InterventionPage extends StatefulWidget {
  const InterventionPage({super.key, required this.orderCode});

  final String orderCode;

  @override
  State<InterventionPage> createState() => _InterventionPageState();
}

class _InterventionPageState extends State<InterventionPage> {
  final _diagnosis = TextEditingController(
    text: 'Condensador obstruido y termostato descalibrado; el compresor no realiza ciclos de apagado.',
  );
  final Map<String, bool> _actions = {
    'Limpieza de condensador': true,
    'Recalibración de termostato': true,
    'Recarga de refrigerante': false,
    'Cambio de filtro': false,
  };
  final List<String> _parts = ['Termostato digital XR06'];
  int _photos = 2;
  late final String _localId = AppState.instance.nextLocalId();

  @override
  void dispose() {
    _diagnosis.dispose();
    super.dispose();
  }

  void _finish() {
    final app = AppState.instance;
    final sent = app.submitIntervention(Intervention(
      localId: _localId,
      orderCode: widget.orderCode,
      diagnosis: _diagnosis.text,
      actions: _actions.entries.where((e) => e.value).map((e) => e.key).toList(),
      spareParts: List.of(_parts),
      photoCount: _photos,
    ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: sent ? AppColors.success : AppColors.offline,
      content: Text(sent ? tr('sentOnline') : tr('savedOffline')),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final app = AppState.instance;
      final order = app.orderByCode(widget.orderCode)!;
      final text = Theme.of(context).textTheme;
      return Scaffold(
        appBar: AppBar(title: Text(tr('registerIntervention'))),
        body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
          if (app.isOffline) ...[SyncBanner(message: tr('offlineBanner')), const SizedBox(height: 12)],
          Row(children: [
            Expanded(child: Text('${order.code} · ${order.equipmentId}', style: const TextStyle(fontWeight: FontWeight.w600))),
            OrderStatusBadge(status: order.status),
          ]),
          const SizedBox(height: 16),
          Text(tr('diagnosis'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: _diagnosis, maxLines: 3, decoration: InputDecoration(hintText: tr('diagnosisHint'))),
          const SizedBox(height: 16),
          Text(tr('actionsDone'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final entry in _actions.entries)
              Chip2(
                label: entry.key,
                isSelected: entry.value,
                showCheck: true,
                onTap: () => setState(() => _actions[entry.key] = !entry.value),
              ),
          ]),
          const SizedBox(height: 16),
          Text(tr('spareParts'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final part in _parts) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                const IconCircle(icon: Icons.inventory_2_outlined, color: AppColors.primary, size: 36),
                const SizedBox(width: 12),
                Expanded(child: Text(part, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('×1', style: AppTheme.numeric()),
              ]),
            ),
            const SizedBox(height: 8),
          ],
          TextButton.icon(
            onPressed: () => setState(() => _parts.add('Filtro deshidratador FD-16')),
            icon: const Icon(Icons.add),
            label: Text(tr('addPart')),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(tr('evidence'), style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('$_photos / 5', style: AppTheme.numeric(color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (var i = 0; i < _photos; i++)
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  gradient: const LinearGradient(colors: [Color(0xFFD1DDEB), Color(0xFF64738C)]),
                ),
                child: const Icon(Icons.image_outlined, color: Colors.white),
              ),
            if (_photos < 5)
              GestureDetector(
                onTap: () => setState(() => _photos++),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    border: Border.all(color: AppColors.accent),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                    Text(tr('addPhoto'), style: text.bodySmall?.copyWith(color: AppColors.primary)),
                  ]),
                ),
              ),
          ]),
        ]),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FilledButton(onPressed: _finish, child: Text(tr('finishService'))),
              const SizedBox(height: 8),
              Text('${tr('localId')} $_localId · ${tr('localIdNote')}', textAlign: TextAlign.center, style: text.bodySmall),
            ]),
          ),
        ),
      );
    });
  }
}
