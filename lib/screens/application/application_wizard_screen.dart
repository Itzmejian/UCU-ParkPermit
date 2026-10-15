import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_limits.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../models/application_draft.dart';
import '../../models/application_store.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/icon_badge.dart';
import 'step_documents.dart';
import 'step_review.dart';
import 'step_vehicle_details.dart';
import 'step_vehicle_type.dart';

enum _ExitChoice { save, discard, keep }

class ApplicationWizardScreen extends StatefulWidget {
  const ApplicationWizardScreen({super.key});

  @override
  State<ApplicationWizardScreen> createState() =>
      _ApplicationWizardScreenState();
}

class _ApplicationWizardScreenState extends State<ApplicationWizardScreen> {
  static const List<String> _sectionLabels = [
    'VEHICLE CLASSIFICATION',
    'VEHICLE INFORMATION',
    'DOCUMENT UPLOAD',
    'FINAL REVIEW',
  ];

  final ApplicationStore _store = ApplicationStore.instance;
  late final ApplicationDraft _draft;
  int _step = 0;
  bool _submitting = false;

  bool get _limitReached => _store.draft == null && _store.limitReached;

  @override
  void initState() {
    super.initState();
    _draft = _store.draft?.clone() ?? ApplicationDraft();
    _step = _draft.step < 0 ? 0 : (_draft.step > 3 ? 3 : _draft.step);
  }

  void _next() => setState(() => _step++);

  void _back() => setState(() => _step--);

  void _goTo(int step) => setState(() => _step = step);

  Future<void> _handleBack() async {
    if (_step > 0 && !_submitting) {
      _back();
      return;
    }
    await _confirmExit();
  }

  Future<_ExitChoice?> _askExit() {
    return showDialog<_ExitChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this application?'),
        content: const Text(
          'Do you want to save what you filled in as a draft so you can continue later?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitChoice.keep),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitChoice.discard),
            child: const Text(
              'Discard',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitChoice.save),
            child: const Text(
              'Save draft',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit() async {
    if (!_draft.hasAnyData) {
      Navigator.pop(context);
      return;
    }
    final choice = await _askExit();
    if (!mounted) return;
    if (choice == _ExitChoice.save) {
      _saveDraftAndLeave();
    } else if (choice == _ExitChoice.discard) {
      _store.discardDraft();
      Navigator.pop(context);
    }
  }

  void _saveDraftAndLeave() {
    _draft.step = _step;
    _store.saveDraft(_draft.clone());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved. Continue anytime from Home.')),
    );
    Navigator.pop(context);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    // TODO: upload the files to Supabase Storage and create the application row.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final sub = _store.submit(_draft.clone());
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.applicationSubmitted,
      arguments: sub.referenceNo,
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_step + 1) / 4,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_step + 1} of 4',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              Text(
                _sectionLabels[_step],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return StepVehicleType(
          key: const ValueKey('step0'),
          draft: _draft,
          onNext: _next,
          onCancel: _confirmExit,
        );
      case 1:
        return StepVehicleDetails(
          key: const ValueKey('step1'),
          draft: _draft,
          onNext: _next,
          onBack: _back,
          onSaveDraft: _saveDraftAndLeave,
        );
      case 2:
        return StepDocuments(
          key: const ValueKey('step2'),
          draft: _draft,
          onNext: _next,
          onBack: _back,
          onSaveDraft: _saveDraftAndLeave,
        );
      default:
        return StepReview(
          key: const ValueKey('step3'),
          draft: _draft,
          submitting: _submitting,
          onSubmit: _submit,
          onBack: _back,
          onSaveDraft: _saveDraftAndLeave,
          onEdit: _goTo,
        );
    }
  }

  Widget _limitBody() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(
              icon: Icons.directions_car_filled_outlined,
              background: AppColors.errorLight,
              foreground: AppColors.error,
            ),
            const SizedBox(height: 20),
            const Text(
              'Vehicle limit reached',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can register up to $kMaxVehicles vehicles, and a pending application counts as one. Remove a vehicle or wait for a permit to expire before adding another.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Back to Dashboard',
              onPressed: () => Navigator.pop(context),
            ),
            if (_store.debugSlots != null)
              TextButton(
                onPressed: () => setState(() => _store.debugSlots = null),
                child: const Text('Testing: reset vehicle count'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          centerTitle: true,
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Permit Application',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              Text(
                'UCU PARKPERMIT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.goldDark,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Help',
              icon: const Icon(Icons.help_outline),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.permitRequirements),
            ),
          ],
        ),
        body: SafeArea(
          child: _limitReached
              ? _limitBody()
              : Column(
                  children: [
                    _progress(),
                    Expanded(child: _stepBody()),
                    if (kShowDevTools && _step == 0)
                      TextButton(
                        onPressed: () =>
                            setState(() => _store.debugSlots = kMaxVehicles),
                        child: const Text(
                          'Testing: simulate 2 registered vehicles',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}