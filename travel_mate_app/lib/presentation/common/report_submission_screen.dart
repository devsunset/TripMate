import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:travel_mate_app/app/theme.dart';
import 'package:travel_mate_app/app/constants.dart';
import 'package:travel_mate_app/presentation/common/report_button_widget.dart';
import 'package:travel_mate_app/presentation/common/app_app_bar.dart';

/// 신고 사유 작성·제출 화면.
class ReportSubmissionScreen extends StatefulWidget {
  final ReportEntityType entityType;
  final String entityId;
  final String reporterUserId;

  const ReportSubmissionScreen({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.reporterUserId,
  });

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReportType;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _reportTypes = [
    '스팸',
    '혐오 발언',
    '괴롭힘',
    '부적절한 콘텐츠',
    '사칭',
    '자해·위험',
    '기타',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedReportType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고 유형을 선택하세요.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // TODO: Implement actual report submission logic using SubmitReport usecase
        // final submitReport = Provider.of<SubmitReport>(context, listen: false);
        // await submitReport.execute(
        //   reporterUserId: widget.reporterUserId,
        //   entityType: widget.entityType,
        //   entityId: widget.entityId,
        //   reportType: _selectedReportType!,
        //   reason: _reasonController.text.trim(),
        // );

        await Future.delayed(const Duration(seconds: 1)); // Simulate network

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('신고가 접수되었습니다.')),
          );
          context.pop(); // Go back after submitting report
        }
      } catch (e) {
        setState(() {
          _errorMessage = '신고 접수 실패: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: '신고하기'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '신고하기 (대상 ID: ${widget.entityId})',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppConstants.spacingLarge),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedReportType != null && _reportTypes.contains(_selectedReportType) ? _selectedReportType : null,
                      decoration: const InputDecoration(
                        labelText: '신고 유형',
                        prefixIcon: Icon(Icons.report_problem),
                      ),
                      items: _reportTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedReportType = newValue;
                        });
                      },
                      validator: (value) => value == null ? '신고 유형을 선택하세요' : null,
                    ),
                    const SizedBox(height: AppConstants.spacingMedium),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: '추가 설명 (선택)',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: AppConstants.spacingLarge),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                        ),
                        child: Text(
                          '신고 접수',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
