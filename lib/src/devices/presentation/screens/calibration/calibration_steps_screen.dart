import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_graphics/vector_graphics.dart';
import '../../../../../core/components/fancy_loading.dart';
import '../../../../../pkg.dart';
import '../../../application/controllers/calibration_controller.dart';
import '../../../application/controllers/devices_controller.dart';
import '../../../application/states/calibration_state.dart';
import '../../../domain/entities/calibration_step_def_entity.dart';
import '../../../domain/entities/calibration_timer_entity.dart';
import '../../widgets/cardlike_container_widget.dart';
import '../devices_screen.dart';

class CalibrationStepsScreen extends ConsumerStatefulWidget {
  static const String path = 'calibration-steps';
  final String serial;

  const CalibrationStepsScreen({super.key, required this.serial});

  @override
  ConsumerState<CalibrationStepsScreen> createState() => _CalibrationStepsScreenState();
}

class _CalibrationStepsScreenState extends ConsumerState<CalibrationStepsScreen> {
  final ScrollController _scrollController = ScrollController();

  // Ditangkap sekali di initState (saat ref masih pasti valid), dipakai lagi
  // di dispose() — JANGAN PERNAH panggil ref.read(...) langsung di dispose(),
  // karena pada saat itu widget bisa sudah "defunct" (terutama saat ada
  // predictive-back/pop-restore beruntun dari GoRouter) dan ref jadi unsafe.
  late final CalibrationController _controller;

  // Hanya dipakai untuk re-render label countdown tiap detik.
  // Sumber kebenaran tetap `timer.endsAt` dari server/socket, BUKAN variabel lokal ini.
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(calibrationControllerProvider(widget.serial).notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // init(): GET /steps + GET /:serial/session (resume/reconnect) + join socket room
      _controller.init(widget.serial);
    });

    // Tick tiap detik hanya untuk memaksa rebuild text countdown.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final state = ref.read(calibrationControllerProvider(widget.serial));
      if (state.phase == CalibrationPhase.soaking) {
        // Trigger transisi ke readyToComplete saat timer habis
        final timer = state.activeTimer;
        if (timer != null) {
          final isExpired = timer.endsAt.isBefore(DateTime.now());
          if (isExpired) {
            _controller.onSoakCompleted(widget.serial);
          }
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _scrollController.dispose();
    // Pakai reference yang sudah ditangkap, BUKAN ref.read() lagi di sini.
    _controller.leaveRoom(widget.serial);
    super.dispose();
  }

  // ─── Cancel Confirmation ────────────────────────────────────────────────────

  void _onCancelPressed(AppLocalizations local) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => alertDialog(
        context: ctx,
        title: local.cancelCalibrationTitle,
        content: local.cancelCalibrationMessage,
        onConfirm: () async {
          await _controller.cancel(widget.serial);
          if (context.mounted) context.pop();
        },
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final state = ref.watch(calibrationControllerProvider(widget.serial));

    // Auto-scroll chip ke step aktif setiap currentStepIndex berubah
    ref.listen(calibrationControllerProvider(widget.serial), (prev, next) {
      final prevIndex = prev?.session?.currentStepIndex;
      final nextIndex = next.session?.currentStepIndex;
      if (prevIndex != nextIndex && nextIndex != null) {
        _scrollToStep(nextIndex);
      }

      // applyStep() di controller cuma set phase ke `applying`, TIDAK
      // menampilkan apapun sendiri — screen ini yang wajib munculkan
      // bottom sheet "X Calibration Applied". Pakai `prev` (state SEBELUM
      // session di-advance) untuk tahu tipe yang baru saja di-apply, karena
      // `next.currentStepDef` sudah menunjuk ke step berikutnya.
      final justEnteredApplying =
          next.phase == CalibrationPhase.applying && prev?.phase != CalibrationPhase.applying ||
          next.phase == CalibrationPhase.done && prev?.phase != CalibrationPhase.done;
      if (justEnteredApplying) {
        final appliedStep = prev?.currentStepDef;
        final upcomingStep = next.currentStepDef;
        if (appliedStep == null || upcomingStep == null) return;
        ApplyCalibrationSheet.show(
          context,
          nextStepLabel: _shortLabel(upcomingStep),
          isLast: next.isLastStep,
          image: next.isLastStep ? ImageAssets.applyPPMCalibration : ImageAssets.applypHCalibration,
          onContinue: () {
            Navigator.of(context).pop();
            _controller.confirmAppliedAndContinue(widget.serial);

            if (next.isLastStep) {
              // Kalau sudah selesai semua step, langsung kembali ke DevicesScreen
              context.go('/${DevicesScreen.path}');
              ref.invalidate(devicesControllerProvider);
            }
          },
        );
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ColorValues.neutral50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            decoration: BoxDecoration(
              color: ColorValues.whiteColor,
              shape: BoxShape.circle,
              border: Border.all(color: ColorValues.neutral200),
            ),
            margin: EdgeInsets.only(left: 16.w),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: ColorValues.blackColor),
              // Jangan biarkan keluar tanpa konfirmasi saat soak berjalan
              onPressed: state.phase == CalibrationPhase.soaking
                  ? () {
                      context.pop();
                      context.go('/${DevicesScreen.path}');
                      ref.invalidate(devicesControllerProvider);
                    }
                  : () => context.pop(),
            ),
          ),
          title: Text(local.deviceCalibration, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          actions: [
            if (state.phase != CalibrationPhase.done && state.phase != CalibrationPhase.loading && state.phase != CalibrationPhase.cancelled)
              Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: TextButton(
                  onPressed: () => _onCancelPressed(local),
                  child: Text(local.cancel, style: const TextStyle(color: ColorValues.danger600)),
                ),
              ),
          ],
        ),
        body: switch (state.phase) {
          CalibrationPhase.loading => Center(child: FancyLoading(title: local.initializingCalibration)),
          CalibrationPhase.error => _buildErrorView(state, local),
          CalibrationPhase.cancelled => _buildCancelledView(local),

          _ => _buildStepView(state, local),
        },
      ),
    );
  }

  void _scrollToStep(int index) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (index * (widthQuery(context) * 0.2 + 12)).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ─── Error / Cancelled / Done Views ─────────────────────────────────────────

  Widget _buildErrorView(CalibrationState state, AppLocalizations local) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_outlined, color: ColorValues.danger600, size: 50),
            Text(local.error, style: jetBrainsMonoHeadText(color: ColorValues.danger600, size: 20)),
            const SizedBox(height: 8),
            Text(
              state.error.toString().replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: dmSansSmallText(size: 14, weight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: primaryButton(text: local.tryAgain, context: context, onPressed: () => _controller.init(widget.serial)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledView(AppLocalizations local) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_outlined, color: ColorValues.neutral400, size: 50),
            const SizedBox(height: 8),
            Text(local.calibrationCancelledMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: primaryButton(text: local.back, context: context, onPressed: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Step View ──────────────────────────────────────────────────────────

  Widget _buildStepView(CalibrationState state, AppLocalizations local) {
    final stepDef = state.currentStepDef;
    if (stepDef == null) return const SizedBox.shrink();

    final chainToApply = _willChainToApply(state, stepDef);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            _buildStepIndicator(state),
            const SizedBox(height: 16),
            _buildTitleCard(state, stepDef, local, chainToApply),
            const SizedBox(height: 16),
            _buildImageCard(state, stepDef, local, chainToApply),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: _buildButton(state, stepDef, local, chainToApply)),
          ],
        ),
      ),
    );
  }

  /// True jika step SAAT INI adalah langkah soak terakhir dari tipenya —
  /// yaitu step berikutnya dalam urutan `allSteps` adalah langkah "simpan"
  /// tanpa soak (calc/calctds). Dipakai untuk menyembunyikan langkah
  /// "Continue to Save pH/TDS" dari UI: tombol langsung jadi
  /// "Apply X Calibration", dan controller akan mengeksekusi calc/calctds
  /// otomatis di belakang layar saat tombol itu ditekan.
  bool _willChainToApply(CalibrationState state, CalibrationStepDefEntity step) {
    final targetIndex = step.index + 1;
    for (final s in state.allSteps) {
      if (s.index == targetIndex) return !s.requiresSoak;
    }
    return false;
  }

  // ─── Step Indicator (chip row — visual sama seperti versi Figma) ─────────────

  Widget _buildStepIndicator(CalibrationState state) {
    final currentIndex = state.session?.currentStepIndex ?? 0;

    // 'enter_cal' bukan langkah yang relevan ditampilkan sebagai chip terpisah —
    // ia sudah otomatis terjadi saat POST /start.
    final visibleSteps = state.allSteps.where((s) => s.action != 'enter_cal').toList();

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: Row(
          children: [
            for (final step in visibleSteps) step.action.contains('calc') ? const SizedBox.shrink() : _buildStepChip(step, currentIndex, state.phase),
          ],
        ),
      ),
    );
  }

  Widget _buildStepChip(CalibrationStepDefEntity step, int currentIndex, CalibrationPhase phase) {
    final isActive = step.index == currentIndex;
    final isPastStep = step.index < currentIndex;
    final isFinishedActiveStep = isActive && (phase == CalibrationPhase.readyToComplete || phase == CalibrationPhase.applying);
    final isFinished = isPastStep || isFinishedActiveStep;

    final shortLabel = _shortLabel(step);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: widthQuery(context) * 0.2,
      decoration: BoxDecoration(
        color: isActive || isFinished ? ColorValues.whiteColor : ColorValues.neutral100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isActive && (phase == CalibrationPhase.idle || phase == CalibrationPhase.soaking)
              ? ColorValues.blueProgress
              : isFinished
              ? ColorValues.success600
              : ColorValues.neutral100,
          width: isActive || isFinished ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VectorGraphic(loader: AssetBytesLoader(step.phase == 'PH' ? IconAssets.phMax : IconAssets.ppmMax), width: 18, height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              step.phase == 'PH' ? 'pH' : 'PPM',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: ColorValues.blueProgress),
            ),
          ),
          Text(
            shortLabel.replaceAll('pH ', '').replaceAll('PPM ', ''),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: ColorValues.blackColor),
          ),
        ],
      ),
    );
  }

  // ─── Title Card ────────────────────────────────────────────────────────────

  Widget _buildTitleCard(CalibrationState state, CalibrationStepDefEntity step, AppLocalizations local, bool chainToApply) {
    final label = _displayLabel(step.action);

    final (title, subtitle) = switch (state.phase) {
      CalibrationPhase.idle when step.requiresSoak => ('${local.calibrate} $label', local.placeSensor(_typeOf(step), _valueOf(step))),
      CalibrationPhase.idle => ('$label ${local.calibrated}', local.readyToApplyCalibration),
      CalibrationPhase.soaking => ('${local.calibrate} $label', local.calibrationInProgress),
      CalibrationPhase.readyToComplete => (
        '$label ${local.calibrated}',
        chainToApply && !state.isLastStep ? local.readyToApplyCalibration : local.readyForNextStep,
      ),

      CalibrationPhase.applying => ('$label ${local.calibrated}', local.readyToApplyCalibration),
      _ => (label, ''),
    };

    final isDoneLike = state.phase == CalibrationPhase.readyToComplete || state.phase == CalibrationPhase.applying;

    return CardLikeContainerWidget(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (isDoneLike) ...[const SizedBox(width: 6), const Icon(Icons.check_circle, color: ColorValues.green500, size: 18)],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColorValues.neutral500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Image Card ────────────────────────────────────────────────────────────

  Widget _buildImageCard(CalibrationState state, CalibrationStepDefEntity step, AppLocalizations local, bool chainToApply) {
    final isRinseState = state.phase == CalibrationPhase.readyToComplete || state.phase == CalibrationPhase.applying;
    final isSoaking = state.phase == CalibrationPhase.soaking;
    final type = _typeOf(step);

    final imageAsset = isRinseState ? (type == 'pH' ? ImageAssets.pHRinse : ImageAssets.ppmRinse) : _getStepImage(step.action);

    final caption = isRinseState
        ? (!chainToApply ? local.rinseBeforeNextStep : local.rinseAndReturnToHolder)
        : isSoaking
        ? local.calibrationIsInProgress
        : local.keepTheSensorSubmerged;

    return CardLikeContainerWidget(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: heightQuery(context) * 0.24,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: Image.asset(imageAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: widthQuery(context) * 0.6,
              child: Text(
                caption,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColorValues.blackColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepImage(String action) {
    return switch (action) {
      'cal7' => ImageAssets.pH7,
      'cal4' => ImageAssets.pH4,
      'calc' => ImageAssets.pHRinse,
      'cal500' => ImageAssets.ppm500,
      'cal1000' => ImageAssets.ppm1000,
      'cal1382' => ImageAssets.ppm1382,
      'calctds' => ImageAssets.ppmRinse,
      _ => ImageAssets.pH7,
    };
  }

  String _typeOf(CalibrationStepDefEntity step) => step.phase == 'PH' ? 'pH' : 'PPM';

  String _shortLabel(CalibrationStepDefEntity step) {
    return switch (step.action) {
      'cal7' => 'pH 7',
      'cal4' => 'pH 4',
      'calc' => 'Save pH',
      'cal500' => 'PPM 500',
      'cal1000' => 'PPM 1000',
      'cal1382' => 'PPM 1382',
      'calctds' => 'Save TDS',
      _ => step.label,
    };
  }

  double _valueOf(CalibrationStepDefEntity step) {
    return switch (step.action) {
      'cal7' => 7,
      'cal4' => 4,
      'cal500' => 500,
      'cal1000' => 1000,
      'cal1382' => 1382,
      _ => 0,
    };
  }

  String _displayLabel(String action) {
    return switch (action) {
      'cal7' => 'pH 7.0',
      'cal4' => 'pH 4.0',
      'calc' => 'pH Calibrated',
      'cal500' => 'PPM 500',
      'cal1000' => 'PPM 1000',
      'cal1382' => 'PPM 1382',
      'calctds' => 'PPM',
      _ => action,
    };
  }

  // ─── Button ────────────────────────────────────────────────────────────────

  Widget _buildButton(CalibrationState state, CalibrationStepDefEntity step, AppLocalizations local, bool chainToApply) {
    final controller = _controller;
    final isLoading = state.isActionLoading;

    return switch (state.phase) {
      // Step butuh soak, belum dimulai → tampilkan estimasi waktu dari /estimate-time/:step
      CalibrationPhase.idle when step.requiresSoak => primaryButton(
        text: state.currentStepEstimateMin != null ? local.beginCalibration(state.currentStepEstimateMin.toString()) : local.startCalibration,
        onPressed: isLoading ? () {} : () => controller.beginSoak(widget.serial),
        context: context,
      ),

      // Step tanpa soak (calc/calctds) — fallback untuk kasus reconnect yang
      // mendarat tepat di step ini (di luar alur normal yang sudah di-chain
      // otomatis dari readyToComplete di bawah).
      CalibrationPhase.idle => primaryButton(
        text: '${local.apply} ${_typeOf(step)} ${local.calibration}',
        onPressed: isLoading ? () {} : () => controller.applyStep(widget.serial),
        context: context,
      ),

      // Soaking → disabled, tampilkan sisa waktu dihitung dari ends_at (server-driven)
      CalibrationPhase.soaking => secondaryButton(
        text: _formatRemaining(state.activeTimer),
        onPressed: () {},
        context: context,
        color: ColorValues.neutral200,
      ),

      // Timer habis → SELALU panggil completeCurrentStep. Kalau step ini
      // adalah soak terakhir suatu tipe (chainToApply true), controller akan
      // otomatis chain ke calc/calctds di belakang layar dan langsung
      // memunculkan ApplyCalibrationSheet — user tidak pernah melihat
      // "Continue to Save pH/TDS" sebagai langkah terpisah.
      CalibrationPhase.readyToComplete => primaryButton(
        text: chainToApply ? '${local.apply} ${_typeOf(step)} ${local.calibration}' : local.continueTo(state.nextStepShortLabel ?? ''),
        onPressed: isLoading ? () {} : () => controller.completeCurrentStep(widget.serial),
        context: context,
      ),

      CalibrationPhase.applying => primaryButton(text: local.saving, onPressed: () {}, context: context),

      _ => const SizedBox.shrink(),
    };
  }

  String _formatRemaining(CalibrationTimerEntity? timer) {
    if (timer == null) return '--:--';
    final remaining = timer.endsAt.difference(DateTime.now()).inSeconds;
    final clamped = remaining < 0 ? 0 : remaining;
    final m = clamped ~/ 60;
    final s = clamped % 60;
    final local = AppLocalizations.of(context)!;
    return local.timeRemaining('${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}');
  }
}

// ─── Bottom Sheet: Apply Calibration (dipanggil dari controller saat applyStep sukses) ──

class ApplyCalibrationSheet extends StatelessWidget {
  final String nextStepLabel;
  final VoidCallback onContinue;
  final String image;
  final bool isLast;

  const ApplyCalibrationSheet({super.key, required this.nextStepLabel, required this.onContinue, required this.image, required this.isLast});

  static void show(
    BuildContext context, {
    required String nextStepLabel,
    required String image,
    required VoidCallback onContinue,
    required bool isLast,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: ColorValues.whiteColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => ApplyCalibrationSheet(nextStepLabel: nextStepLabel, image: image, onContinue: onContinue, isLast: isLast),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 50),
          Text(
            local.calibrationAppliedTitle(isLast ? 'PPM' : 'pH'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: ColorValues.blackColor),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Image.asset(image, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text(
            isLast ? local.calibrationFullyAppliedMessage : local.calibrationReadyForNextType(nextStepLabel),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColorValues.blackColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: primaryButton(text: isLast ? local.finish : local.continueTo(nextStepLabel), onPressed: onContinue, context: context),
          ),
        ],
      ),
    );
  }
}
