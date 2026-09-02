import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import '../screens/phone_login_screen.dart';

const _kRed = Color(0xFF9F1D1F);

/// Gate any write/post action behind login. Returns true only if the user is
/// (now) authenticated. If not, shows a prompt and opens the login screen on
/// accept. Usage: `if (!await requireLogin(context)) return;`
Future<bool> requireLogin(
  BuildContext context, {
  String? message,
}) async {
  if (FirebaseAuth.instance.currentUser != null) return true;

  final msg = message ?? t('login_gate.default_message');

  final go = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const Icon(Icons.lock_outline_rounded, color: _kRed, size: 40),
            const SizedBox(height: 12),
            Text(t('login_gate.title'),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(t('login_gate.log_in'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('login_gate.cancel'), style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    ),
  );

  if (go != true || !context.mounted) return false;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
  return FirebaseAuth.instance.currentUser != null;
}
