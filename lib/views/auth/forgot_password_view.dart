import 'package:chat_app/controllers/forgot_password_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.goBackToLogin,
                      icon: Icon(Icons.arrow_back),
                    ),
                    Text(
                      'Forgot Password',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 56),
                  child: Text(
                    'Enter Your Email to recieve a password reset link',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),

                SizedBox(height: 60),
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),

                SizedBox(height: 40),
                Obx(() {
                  if (controller.emailSent) {
                    return _buildEmailSentContent(controller);
                    // return SizedBox();
                  } else {
                    return _buildEmailForm(controller);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(ForgotPasswordController controller) {
    return Column(
      children: [
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
            hintText: 'Enter Your Email',
          ),
          validator: controller.validateEmail,
        ),
        SizedBox(height: 32),
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : controller.sentPasswordResetEmail,
              icon: controller.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.send),
              label: Text(
                controller.isLoading ? 'sending...' : 'Send Rest Link',
              ),
            ),
          ),
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Remeber Your Password ? ',
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: controller.goBackToLogin,
              child: Text(
                'Sign In',
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailSentContent(ForgotPasswordController controller) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read_rounded,
                size: 60,
                color: AppTheme.successColor,
              ),
              SizedBox(height: 16),
              Text(
                'Email Sent!',
                style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "We've sent a password resent link to your",
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                controller.emailController.text,
                style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Check your Email and follow the instuctions to resent your Password',
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: controller.resentEmail,
            icon: Icon(Icons.refresh),
            label: Text('Resent Email'),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.goBackToLogin,
            icon: Icon(Icons.arrow_back),
            label: Text('Back to SignIn'),
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: AppTheme.secondaryColor,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Didn't recieve the Mail? Check Your Spam folder and try again",
                  style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
