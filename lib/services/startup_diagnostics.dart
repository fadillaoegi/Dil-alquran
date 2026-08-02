import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StartupDiagnostics {
  static final StartupDiagnostics _instance = StartupDiagnostics._internal();

  factory StartupDiagnostics() => _instance;

  StartupDiagnostics._internal();

  static const _activeKey = 'startup_launch_active';
  static const _sessionKey = 'startup_launch_session';
  static const _statusKey = 'startup_launch_status';
  static const _recoveryModeKey = 'startup_recovery_mode';
  static const _eventsKey = 'startup_launch_events';
  static const _maxEvents = 40;

  Future<StartupLaunchState> beginLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final previousLaunchIncomplete = prefs.getBool(_activeKey) ?? false;
    final sessionId = DateTime.now().toIso8601String();

    await prefs.setBool(_activeKey, true);
    await prefs.setString(_sessionKey, sessionId);
    await prefs.setString(_statusKey, 'starting');
    await prefs.setBool(_recoveryModeKey, previousLaunchIncomplete);

    await logStep(
      'launch.begin',
      state: previousLaunchIncomplete ? 'recovery' : 'ok',
      details: previousLaunchIncomplete
          ? 'Detected unfinished previous launch.'
          : 'Startup session started.',
    );

    return StartupLaunchState(
      sessionId: sessionId,
      recoveryMode: previousLaunchIncomplete,
    );
  }

  Future<void> logStep(
    String label, {
    String state = 'ok',
    String? details,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentSession = prefs.getString(_sessionKey) ?? 'unknown';

    final raw = prefs.getString(_eventsKey);
    final events = <Map<String, dynamic>>[];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              events.add(Map<String, dynamic>.from(item));
            }
          }
        }
      } catch (_) {
        events.clear();
      }
    }

    events.add({
      'session': currentSession,
      'time': DateTime.now().toIso8601String(),
      'label': label,
      'state': state,
      if (details != null && details.isNotEmpty) 'details': details,
    });

    final trimmed = events.length > _maxEvents
        ? events.sublist(events.length - _maxEvents)
        : events;
    await prefs.setString(_eventsKey, jsonEncode(trimmed));
  }

  Future<void> markReady() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, false);
    await prefs.setString(_statusKey, 'ready');
    await prefs.setBool(_recoveryModeKey, false);
    await logStep('launch.ready', details: 'App reached first frame.');
  }

  Future<void> markFailure(String label, Object error) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, 'failed');
    await logStep(
      label,
      state: 'error',
      details: error.toString(),
    );
  }

  Future<StartupDiagnosticsSnapshot> readSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_eventsKey);
    final events = <StartupDiagnosticEvent>[];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              events.add(
                StartupDiagnosticEvent(
                  session: map['session']?.toString() ?? '',
                  time: map['time']?.toString() ?? '',
                  label: map['label']?.toString() ?? '',
                  state: map['state']?.toString() ?? 'ok',
                  details: map['details']?.toString() ?? '',
                ),
              );
            }
          }
        }
      } catch (_) {
        // Abaikan; snapshot tetap dikembalikan dengan event kosong.
      }
    }

    return StartupDiagnosticsSnapshot(
      activeLaunch: prefs.getBool(_activeKey) ?? false,
      recoveryMode: prefs.getBool(_recoveryModeKey) ?? false,
      currentSession: prefs.getString(_sessionKey) ?? '',
      status: prefs.getString(_statusKey) ?? '',
      events: events,
    );
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_eventsKey);
    await prefs.remove(_statusKey);
    await prefs.remove(_sessionKey);
    await prefs.remove(_recoveryModeKey);
    await prefs.setBool(_activeKey, false);
  }
}

class StartupLaunchState {
  final String sessionId;
  final bool recoveryMode;

  const StartupLaunchState({
    required this.sessionId,
    required this.recoveryMode,
  });
}

class StartupDiagnosticsSnapshot {
  final bool activeLaunch;
  final bool recoveryMode;
  final String currentSession;
  final String status;
  final List<StartupDiagnosticEvent> events;

  const StartupDiagnosticsSnapshot({
    required this.activeLaunch,
    required this.recoveryMode,
    required this.currentSession,
    required this.status,
    required this.events,
  });
}

class StartupDiagnosticEvent {
  final String session;
  final String time;
  final String label;
  final String state;
  final String details;

  const StartupDiagnosticEvent({
    required this.session,
    required this.time,
    required this.label,
    required this.state,
    required this.details,
  });
}
