import 'package:dilalquran/services/startup_diagnostics.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/widgets/app_notify.dart';
import 'package:flutter/material.dart';

class StartupDebugScreen extends StatefulWidget {
  const StartupDebugScreen({super.key});

  @override
  State<StartupDebugScreen> createState() => _StartupDebugScreenState();
}

class _StartupDebugScreenState extends State<StartupDebugScreen> {
  final StartupDiagnostics _diagnostics = StartupDiagnostics();
  StartupDiagnosticsSnapshot? _snapshot;
  bool _isLoading = true;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    setState(() => _isLoading = true);
    final snapshot = await _diagnostics.readSnapshot();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    if (_isClearing) return;
    setState(() => _isClearing = true);
    await _diagnostics.clearLogs();
    await _loadSnapshot();
    if (!mounted) return;
    setState(() => _isClearing = false);
    showAppSnackbar(
      'Log Dibersihkan',
      'Riwayat startup lokal telah dihapus.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.secondary,
      appBar: AppBar(
        backgroundColor: ColorApp.primary,
        iconTheme: const IconThemeData(color: ColorApp.white),
        title: Text(
          'Startup Diagnostics',
          style: primary700.copyWith(fontSize: 18.0, color: ColorApp.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadSnapshot,
            icon: const Icon(Icons.refresh_rounded, color: ColorApp.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ColorApp.primary),
            )
          : RefreshIndicator(
              color: ColorApp.primary,
              onRefresh: _loadSnapshot,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 28.0),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16.0),
                  _buildActionsCard(),
                  const SizedBox(height: 16.0),
                  _buildEventsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final snapshot = _snapshot!;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Startup', style: primary700.copyWith(fontSize: 16.0)),
          const SizedBox(height: 14.0),
          _summaryRow('Status', snapshot.status.isEmpty ? '-' : snapshot.status),
          _summaryRow(
            'Launch aktif',
            snapshot.activeLaunch ? 'Ya' : 'Tidak',
          ),
          _summaryRow(
            'Recovery mode',
            snapshot.recoveryMode ? 'Aktif' : 'Tidak',
          ),
          _summaryRow(
            'Session terakhir',
            snapshot.currentSession.isEmpty ? '-' : snapshot.currentSession,
          ),
          _summaryRow(
            'Jumlah event',
            snapshot.events.length.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aksi Cepat', style: primary700.copyWith(fontSize: 16.0)),
          const SizedBox(height: 14.0),
          Text(
            'Halaman ini membantu mengecek apakah app pernah macet saat startup dan tahap mana yang terakhir tercatat.',
            style: black400.copyWith(
              fontSize: 13.0,
              color: ColorApp.black.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadSnapshot,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isClearing ? null : _clearLogs,
                  icon: Icon(
                    _isClearing
                        ? Icons.hourglass_top_rounded
                        : Icons.delete_outline_rounded,
                  ),
                  label: Text(_isClearing ? 'Membersihkan' : 'Clear Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorApp.primary,
                    foregroundColor: ColorApp.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsCard() {
    final events = _snapshot!.events.reversed.toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Riwayat Event', style: primary700.copyWith(fontSize: 16.0)),
          const SizedBox(height: 14.0),
          if (events.isEmpty)
            Text(
              'Belum ada event startup yang tersimpan.',
              style: black400.copyWith(
                fontSize: 13.0,
                color: ColorApp.black.withValues(alpha: 0.65),
              ),
            )
          else
            ...events.map(_eventTile),
        ],
      ),
    );
  }

  Widget _eventTile(StartupDiagnosticEvent event) {
    final stateColor = switch (event.state) {
      'error' => const Color(0xffc0392b),
      'recovery' => const Color(0xffd98a1f),
      'skipped' => const Color(0xff8e6b09),
      'start' => ColorApp.primary,
      _ => const Color(0xff11623f),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.secondary,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: stateColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9.0,
                height: 9.0,
                decoration: BoxDecoration(
                  color: stateColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  event.label,
                  style: primary700.copyWith(
                    fontSize: 13.5,
                    color: ColorApp.black,
                  ),
                ),
              ),
              Text(
                event.state,
                style: primary700.copyWith(fontSize: 12.0, color: stateColor),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          SelectableText(
            event.time,
            style: black400.copyWith(
              fontSize: 12.0,
              color: ColorApp.black.withValues(alpha: 0.55),
            ),
          ),
          if (event.session.isNotEmpty) ...[
            const SizedBox(height: 4.0),
            SelectableText(
              'session: ${event.session}',
              style: black400.copyWith(
                fontSize: 12.0,
                color: ColorApp.black.withValues(alpha: 0.55),
              ),
            ),
          ],
          if (event.details.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            SelectableText(
              event.details,
              style: black400.copyWith(
                fontSize: 12.5,
                color: ColorApp.black.withValues(alpha: 0.72),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.0,
            child: Text(
              label,
              style: black400.copyWith(
                fontSize: 13.0,
                color: ColorApp.black.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: primary700.copyWith(
                fontSize: 13.5,
                color: ColorApp.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: ColorApp.primary.withValues(alpha: 0.16),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorApp.primary.withValues(alpha: 0.14),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
