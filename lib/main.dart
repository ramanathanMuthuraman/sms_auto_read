import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_auth/smart_auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmsSpikeApp());
}

class SmsSpikeApp extends StatelessWidget {
  const SmsSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Auth SMS Spike',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
      ),
      home: const SmsSpikePage(),
    );
  }
}

class SmsSpikePage extends StatefulWidget {
  const SmsSpikePage({super.key});

  @override
  State<SmsSpikePage> createState() => _SmsSpikePageState();
}

class _SmsSpikePageState extends State<SmsSpikePage> {
  final SmartAuth _smartAuth = SmartAuth.instance;

  String _status = 'Ready';
  String? _appSignature;
  String? _hintPhoneNumber;
  String? _lastSms;
  String? _lastCode;
  bool _busy = false;

  Future<void> _runAction(
    String actionLabel,
    Future<void> Function() action,
  ) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _status = '$actionLabel...';
    });

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _loadAppSignature() async {
    final result = await _smartAuth.getAppSignature();
    if (!mounted) return;

    if (result.hasData) {
      setState(() {
        _appSignature = result.requireData;
        _status = 'App signature loaded.';
        print(_appSignature);
      });
      return;
    }

    setState(() => _status = 'Failed to load app signature: ${result.error}');
  }

  Future<void> _requestPhoneHint() async {
    final result = await _smartAuth.requestPhoneNumberHint();
    if (!mounted) return;

    if (result.hasData) {
      setState(() {
        _hintPhoneNumber = result.requireData;
        _status = 'Phone number hint selected.';
      });
      return;
    }

    if (result.isCanceled) {
      setState(() => _status = 'Phone number hint canceled by user.');
      return;
    }

    setState(() => _status = 'Phone number hint failed: ${result.error}');
  }

  Future<void> _startRetrieverFlow() async {
    final result = await _smartAuth.getSmsWithRetrieverApi();
    if (!mounted) return;

    if (result.hasData) {
      final sms = result.requireData;
      setState(() {
        _lastSms = sms.sms;
        _lastCode = sms.code;
        _status = sms.code == null
            ? 'SMS received via Retriever API, but no code matched your regex.'
            : 'OTP captured via Retriever API.';
      });
      return;
    }

    setState(() => _status = 'Retriever API failed: ${result.error}');
  }

  Future<void> _startUserConsentFlow() async {
    final result = await _smartAuth.getSmsWithUserConsentApi();

    if (!mounted) return;

    if (result.hasData) {
      final sms = result.requireData;
      setState(() {
        _lastSms = sms.sms;
        _lastCode = sms.code;
        _status = sms.code == null
            ? 'SMS received via User Consent, but no code matched your regex.'
            : 'OTP captured via User Consent API.';
      });
      return;
    }

    if (result.isCanceled) {
      setState(() => _status = 'User Consent dialog canceled.');
      return;
    }

    setState(() => _status = 'User Consent API failed: ${result.error}');
  }

  void _clearResults() {
    setState(() {
      _hintPhoneNumber = null;
      _lastSms = null;
      _lastCode = null;
      _status = 'Results cleared.';
    });
  }

  @override
  void dispose() {
    unawaited(_smartAuth.removeUserConsentApiListener());
    unawaited(_smartAuth.removeSmsRetrieverApiListener());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Auth SMS Spike')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              SelectableText('Status: $_status'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            'Loading app signature',
                            _loadAppSignature,
                          ),
                    child: const Text('Get App Signature'),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : _clearResults,
                    child: const Text('Clear Results'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'App Signature',
                child: SelectableText(_appSignature ?? 'Not loaded yet.'),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Phone Number Hint (optional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () => _runAction(
                              'Requesting phone number hint',
                              _requestPhoneHint,
                            ),
                      child: const Text('Request Phone Number Hint'),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(_hintPhoneNumber ?? 'No hint selected yet.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            'Waiting via Retriever API',
                            _startRetrieverFlow,
                          ),
                    child: const Text('Start Retriever API'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            'Waiting via User Consent API',
                            _startUserConsentFlow,
                          ),
                    child: const Text('Start User Consent API'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Extracted OTP',
                child: SelectableText(_lastCode ?? 'No OTP captured yet.'),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Last SMS Body',
                child: SelectableText(_lastSms ?? 'No SMS captured yet.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
