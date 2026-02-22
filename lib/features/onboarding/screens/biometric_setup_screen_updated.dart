import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/uuid_persistence_service.dart';
import '../../../core/widgets/custom_pin_input.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/services/notification_service.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  final String uid;

  const BiometricSetupScreen({super.key, required this.uid});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _isBiometricAvailable = false;
  bool _isLoading = false;
  String _pin = '';
  String _confirmPin = '';
  bool _showPinInput = false;

  @override
  void initState() {
    super.initState();
    print('🔐 BiometricSetupScreen initialized with UID: ${widget.uid}');
    _checkBiometricAvailability();
    _persistUUID();
  }

  Future<void> _persistUUID() async {
    await UUIDPersistenceService.saveUUID(widget.uid);
    await UUIDPersistenceService.backupUUIDToCloud(widget.uid);
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isBiometricAvailable();
    setState(() => _isBiometricAvailable = available);
  }

  Future<void> _setupBiometric() async {
    if (!_isBiometricAvailable) {
      _setupPinFallback();
      return;
    }

    setState(() => _isLoading = true);

    try {
      setState(() => _showPinInput = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupPinFallback() {
    setState(() => _showPinInput = true);
  }

  Future<void> _savePIN() async {
    final security = ref.read(securityProvider.notifier);

    final success = await security.setPinForNewUser(_pin, _confirmPin);

    if (success) {
      if (mounted) {
        NotificationService.showSuccess(context, 'PIN set successfully!');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) context.go('/mode-selection');
        });
      }
    } else {
      final errorMsg = ref.read(securityProvider).errorMessage ?? 'Failed to save PIN';
      if (mounted) {
        NotificationService.showError(context, errorMsg);
      }
    }

    setState(() {
      _pin = '';
      _confirmPin = '';
    });
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip PIN Setup?'),
        content: const Text(
          'Setting up a PIN is recommended for security. You can set it up later in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Setting Up'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/mode-selection');
            },
            child: const Text('Skip for Now', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 1),
              if (!_showPinInput) _buildBiometricStep(),
              if (_showPinInput) _buildPinStep(),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryRose.withOpacity(0.1),
          ),
          child: const Center(
            child: Text('🔒', style: TextStyle(fontSize: 48)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Secure Your Data',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          _isBiometricAvailable
              ? 'Set up a PIN to protect your health data. Biometric authentication is also available.'
              : 'Set up a PIN to protect your health data',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMid,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _setupBiometric,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRose,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 8,
              shadowColor: AppColors.primaryRose.withOpacity(0.4),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Set PIN',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This step is required • Takes less than 1 minute',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    final isFilled = _pin.isNotEmpty && _confirmPin.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRose.withOpacity(0.1),
            ),
            child: const Center(
              child: Text('🔐', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Create Your PIN',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose a 4-digit PIN to protect your data. You\'ll need this to access your account.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMid,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          CustomPinInput(
            label: 'Enter PIN',
            hintText: '• • • •',
            onChanged: (val) => setState(() => _pin = val),
          ),
          const SizedBox(height: 20),
          CustomPinInput(
            label: 'Confirm PIN',
            hintText: '• • • •',
            onChanged: (val) => setState(() => _confirmPin = val),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (isFilled && !_isLoading) ? _savePIN : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRose,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 8,
                shadowColor: AppColors.primaryRose.withOpacity(0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Continue',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleCancel,
            child: const Text(
              'Skip for Now',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
