import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/date_format.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../iam/presentation/sign_in_page.dart';
import '../../shared/presentation/error_text.dart';
import '../application/gateway_service.dart';
import '../domain/model/gateway_state.dart';
import '../infrastructure/edge_gateway_api.dart';

/// On-site tools: local status of the device (US-40), maintenance mode (US-48),
/// buzzer and signal test (US-49). The phone must be on the site's Wi-Fi.
class GatewayToolsPage extends StatefulWidget {
  const GatewayToolsPage({
    super.key,
    required this.requestId,
    required this.siteId,
    required this.equipmentId,
    required this.equipmentName,
    this.defaultDeviceUid,
  });

  final int requestId;
  final int siteId;
  final int equipmentId;
  final String equipmentName;
  final String? defaultDeviceUid;

  @override
  State<GatewayToolsPage> createState() => _GatewayToolsPageState();
}

class _GatewayToolsPageState extends State<GatewayToolsPage> {
  final _service = GatewayService.instance;
  final _url = TextEditingController();
  final _device = TextEditingController();
  bool? _reachable;
  bool _busy = false;
  GatewayState? _state;
  String? _message;
  bool _messageIsError = false;
  bool _offerRenew = false;

  @override
  void initState() {
    super.initState();
    _service
        .savedConnection(siteId: widget.siteId, equipmentId: widget.equipmentId, defaultDeviceUid: widget.defaultDeviceUid)
        .then((saved) {
      if (!mounted) return;
      setState(() {
        _url.text = saved.baseUrl;
        _device.text = saved.deviceUid;
      });
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _device.dispose();
    super.dispose();
  }

  GatewayConnection get _connection =>
      GatewayConnection(baseUrl: _service.normalizeUrl(_url.text), deviceUid: _device.text.trim());

  void _show(String message, {bool isError = false, bool offerRenew = false}) {
    setState(() {
      _message = message;
      _messageIsError = isError;
      _offerRenew = offerRenew;
    });
  }

  Future<void> _testConnection() async {
    final connection = _connection;
    if (!connection.isComplete) {
      _show(tr('gatewayFillFields'), isError: true);
      return;
    }
    setState(() => _busy = true);
    await _service.saveConnection(siteId: widget.siteId, equipmentId: widget.equipmentId, connection: connection);
    final reachable = await _service.isReachable(connection);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _reachable = reachable;
    });
    _show(reachable ? tr('gatewayReachable') : tr('gatewayUnreachable'), isError: !reachable);
  }

  Future<void> _run(Future<GatewayState> Function(GatewayConnection connection) command, String successKey) async {
    final connection = _connection;
    if (!connection.isComplete) {
      _show(tr('gatewayFillFields'), isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.saveConnection(siteId: widget.siteId, equipmentId: widget.equipmentId, connection: connection);
      final state = await command(connection);
      if (!mounted) return;
      setState(() {
        _state = state;
        _reachable = true;
      });
      _show(tr(successKey));
    } on EdgeGatewayException catch (e) {
      if (!mounted) return;
      switch (e.kind) {
        case GatewayErrorKind.unreachable:
          setState(() => _reachable = false);
          _show(tr('gatewayUnreachable'), isError: true);
        case GatewayErrorKind.unauthorized:
          _show(tr('gatewayUnauthorized'), isError: true, offerRenew: true);
        case GatewayErrorKind.conflict:
        case GatewayErrorKind.rejected:
          _show(e.message ?? tr('errorUnexpected'), isError: true);
      }
    } catch (e) {
      // Getting the grant from the backend failed (for example, without internet).
      if (mounted) _show(errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _renewGrant() async {
    setState(() => _busy = true);
    try {
      await _service.renewGrant(widget.requestId);
      if (mounted) _show(tr('gatewayGrantRenewed'));
    } catch (e) {
      if (mounted) _show(errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context) {
      final text = Theme.of(context).textTheme;
      final state = _state;
      final maintenanceOn = state?.maintenanceActive ?? false;
      final buzzerMuted = state?.buzzerMuted ?? false;
      return Scaffold(
        appBar: AppBar(title: Text(tr('gatewayTools'))),
        body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
          Text(widget.equipmentName, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(tr('gatewayIntro'), style: text.bodyMedium?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          SectionTitle(tr('gatewayConnection')),
          const SizedBox(height: 10),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              FieldLabel(tr('gatewayAddress')),
              TextField(
                controller: _url,
                enabled: !_busy,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.router_outlined), hintText: '192.168.1.50:5000'),
              ),
              const SizedBox(height: 12),
              FieldLabel(tr('gatewayDevice')),
              TextField(
                controller: _device,
                enabled: !_busy,
                autocorrect: false,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.memory_outlined), hintText: 'ESP32-ICE-001'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                if (_reachable != null)
                  StatusBadge(
                    label: _reachable! ? tr('gatewayOnline') : tr('gatewayOffline'),
                    color: _reachable! ? AppColors.success : AppColors.offline,
                  ),
                const Spacer(),
                OutlinedButton(onPressed: _busy ? null : _testConnection, child: Text(tr('gatewayTest'))),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          SectionTitle(tr('gatewayDeviceState')),
          const SizedBox(height: 10),
          AppCard(
            child: state == null
                ? Text(tr('gatewayStateUnknown'), style: text.bodySmall)
                : Column(children: [
                    KeyValueRow(
                      icon: Icons.build_outlined,
                      label: tr('maintenanceMode'),
                      value: state.maintenanceActive
                          ? '${tr('active')}${state.maintenanceExpiresAt == null ? '' : ' · ${tr('until')} ${formatTime(state.maintenanceExpiresAt)}'}'
                          : tr('inactive'),
                    ),
                    const SizedBox(height: 12),
                    KeyValueRow(
                      icon: Icons.volume_off_outlined,
                      label: tr('buzzer'),
                      value: state.buzzerMuted ? tr('buzzerMuted') : tr('buzzerNormal'),
                    ),
                    const SizedBox(height: 12),
                    KeyValueRow(
                      icon: Icons.warning_amber_outlined,
                      label: tr('localAlarm'),
                      value: state.alarmActive ? tr('active') : tr('inactive'),
                    ),
                  ]),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            FormMessage(text: _message!, isError: _messageIsError),
            if (_offerRenew)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy || AppState.instance.isOffline ? null : _renewGrant,
                  child: Text(tr('gatewayRenewGrant')),
                ),
              ),
          ],
          const SizedBox(height: 16),
          SectionTitle(tr('gatewayActions')),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(
                      (c) => _service.setMaintenance(widget.requestId, c, active: !maintenanceOn),
                      maintenanceOn ? 'maintenanceEnded' : 'maintenanceStarted',
                    ),
            icon: Icon(maintenanceOn ? Icons.stop_circle_outlined : Icons.build_circle_outlined),
            label: Text(maintenanceOn ? tr('endMaintenance') : tr('startMaintenance')),
          ),
          const SizedBox(height: 8),
          Text(tr('maintenanceHint'), style: text.bodySmall),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(
                      (c) => _service.setBuzzerMuted(widget.requestId, c, muted: !buzzerMuted),
                      buzzerMuted ? 'buzzerRestored' : 'buzzerSilenced',
                    ),
            icon: Icon(buzzerMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined),
            label: Text(buzzerMuted ? tr('restoreBuzzer') : tr('muteBuzzer')),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _run((c) => _service.requestSignalTest(widget.requestId, c), 'signalTestSent'),
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(tr('signalTest')),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ]),
      );
    });
  }
}
