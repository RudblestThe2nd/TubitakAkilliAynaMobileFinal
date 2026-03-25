import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/voice/voice_cubit.dart';

/// Mikrofon butonu + görsel geri bildirim içeren ses asistan widget'ı.
class VoiceAssistantWidget extends StatelessWidget {
  const VoiceAssistantWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceCubit, VoiceState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VoiceStatusBanner(state: state),
            const SizedBox(height: 16),
            _MicButton(state: state),
          ],
        );
      },
    );
  }
}

class _VoiceStatusBanner extends StatelessWidget {
  final VoiceState state;
  const _VoiceStatusBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is VoiceIdle || state is VoiceInitializing) {
      return const SizedBox.shrink();
    }

    String text = '';
    Color color = AppTheme.primary;

    if (state is VoiceListening) {
      final partial = (state as VoiceListening).partialTranscript;
      text = partial.isEmpty ? 'Dinliyorum...' : partial;
      color = AppTheme.accent;
    } else if (state is VoiceProcessing) {
      text = '"${(state as VoiceProcessing).transcript}"';
      color = AppTheme.secondary;
    } else if (state is VoiceSpeaking) {
      text = (state as VoiceSpeaking).response;
      color = AppTheme.success;
    } else if (state is VoiceError) {
      text = (state as VoiceError).failure.message;
      color = AppTheme.error;
    }

    return FadeInUp(
      duration: AppConstants.animNormal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              _iconForState(state),
              color: color,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForState(VoiceState state) {
    if (state is VoiceListening) return Icons.mic;
    if (state is VoiceProcessing) return Icons.psychology;
    if (state is VoiceSpeaking) return Icons.volume_up;
    if (state is VoiceError) return Icons.error_outline;
    return Icons.mic_none;
  }
}

class _MicButton extends StatelessWidget {
  final VoiceState state;
  const _MicButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isListening = state is VoiceListening;
    final isProcessing = state is VoiceProcessing;
    final isSpeaking = state is VoiceSpeaking;
    final isActive = isListening || isProcessing || isSpeaking;

    return GestureDetector(
      onTap: () {
        final cubit = context.read<VoiceCubit>();
        if (isListening) {
          cubit.stopListening();
        } else if (isSpeaking) {
          cubit.stopSpeaking();
        } else {
          cubit.startListening();
        }
      },
      child: AnimatedContainer(
        duration: AppConstants.animNormal,
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppTheme.accent, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : AppTheme.primaryGradient,
          boxShadow: AppShadows.glow(
            color: isActive ? AppTheme.accent : AppTheme.primary,
            blurRadius: isActive ? 28 : 16,
          ),
        ),
        child: isProcessing
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                isListening
                    ? Icons.mic
                    : isSpeaking
                        ? Icons.volume_up
                        : Icons.mic_none,
                color: Colors.white,
                size: 30,
              ),
      ),
    );
  }
}

