import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/uuid_persistence_service.dart';

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
    // Backup to cloud
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
      // For biometric, we still need a PIN as fallback
      setState(() {
        _showPinInput = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupPinFallback() {
    setState(() {
      _showPinInput = true;
    });
  }

  Future<void> _savePIN() async {
    if (_pin.isEmpty || _pin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    if (_pin != _confirmPin) {
      _showError('PINs do not match');
      setState(() {
        _pin = '';
        _confirmPin = '';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('💾 Saving PIN: $_pin');
      final success = await BiometricService.setBiometricPin(_pin);

      print('💾 Save result: $success');

      if (success) {
        print('✅ PIN saved successfully!');
        if (mounted) {
          context.go("/home");
        }
      } else {
        print('❌ PIN save failed');
        _showError('Failed to save PIN');
      }
    } catch (e) {
      print('❌ Exception saving PIN: $e');
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
              ? 'Set up biometric lock to protect your health data'
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
        ElevatedButton(
          onPressed: _isLoading ? null : _setupBiometric,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRose,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Center(
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
                      _isBiometricAvailable ? 'Set Biometric Lock' : 'Set PIN',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
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
            'Choose a 4-digit PIN to protect your data',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMid,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          _buildPinInput(
              'Enter PIN', _pin, (val) => setState(() => _pin = val)),
          const SizedBox(height: 16),
          _buildPinInput('Confirm PIN', _confirmPin,
              (val) => setState(() => _confirmPin = val)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (isFilled && !_isLoading) ? _savePIN : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRose,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinInput(
      String label, String value, Function(String) onChanged) {
    return TextField(
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRose, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
