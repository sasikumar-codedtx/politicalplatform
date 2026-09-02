import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import 'main_shell.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  static const bool _useFirebaseTestPhoneAuth = bool.fromEnvironment(
    'USE_FIREBASE_TEST_PHONE_AUTH',
    defaultValue: false,
  );

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String _verificationId = '';
  String? _error;

  Future<void> _sendOtp() async {
    if (_loading) return; // guard against rapid double-taps
    // Strip everything except digits, then drop leading 91 if user included country code
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('91') && digits.length == 12 ? digits.substring(2) : digits;
    final phone = '+91$local';
    debugPrint('=== sending OTP to: $phone (${phone.length} chars)');
    setState(() { _loading = true; _error = null; });

    if (_useFirebaseTestPhoneAuth && kDebugMode && Platform.isIOS) {
      try {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        debugPrint('=== isPhysicalDevice: ${iosInfo.isPhysicalDevice}');
        debugPrint('=== systemName: ${iosInfo.systemName} ${iosInfo.systemVersion}');
        if (!iosInfo.isPhysicalDevice) {
          await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
          debugPrint('=== appVerificationDisabledForTesting: SET');
        } else {
          debugPrint('=== appVerificationDisabledForTesting: SKIPPED (physical device)');
        }
      } catch (e) {
        debugPrint('=== DeviceInfo error: $e');
      }
    } else if (kDebugMode && Platform.isIOS) {
      debugPrint('=== Firebase test phone auth: DISABLED');
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        _goToDashboard();
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('=== Firebase Phone Auth FAILED ===');
        debugPrint('code: ${e.code}');
        debugPrint('message: ${e.message}');
        debugPrint('plugin: ${e.plugin}');
        debugPrint('stackTrace: ${e.stackTrace}');
        setState(() { _error = '[${e.code}] ${e.message}'; _loading = false; });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _loading = false;
        });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyOtp() async {
    if (_loading) return; // guard against rapid double-taps
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _error = t('phone_login.enter_6_digit_otp'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _goToDashboard();
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  void _goToDashboard() {
    if (!mounted) return;
    // If we were opened over an existing screen (e.g. the login gate that
    // awaits us and then shows the Join-TVK sheet), pop back so that caller
    // resumes on a live context. Only when we're the root do we replace with
    // the shell.
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(AppConfig.current.primaryColor);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        // Scrollable so the form never overflows when the keyboard opens;
        // minHeight + IntrinsicHeight keep the Spacer-centred layout otherwise.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                AppConfig.current.appName,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('phone_login.tagline'),
                style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              if (!_codeSent) ...[
                Text(t('phone_login.enter_mobile_number'),
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    prefixText: '+91  ',
                    hintText: '9876543210',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    counterText: '',
                  ),
                ),
              ] else ...[
                Text(t('phone_login.enter_otp_sent'),
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: t('phone_login.otp_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    counterText: '',
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_codeSent ? _verifyOtp : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _codeSent ? t('phone_login.verify_otp') : t('phone_login.send_otp'),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() { _codeSent = false; _otpController.clear(); }),
                    child: Text(t('phone_login.change_number'), style: TextStyle(color: color)),
                  ),
                ),
              ],
              const Spacer(flex: 2),
            ],
          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
