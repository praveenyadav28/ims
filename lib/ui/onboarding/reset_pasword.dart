import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ims/ui/onboarding/utils/backgraound.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/appbar.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});
  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController confPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: OnboardingBackground(
          widget: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: AppbarClass(title: 'Reset Password'),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: Sizes.height * .04),
                  TitleTextFeild(
                    titleText: "Password",
                    hintText: "Enter New Password",
                    controller: passwordController,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SvgPicture.asset(
                        'assets/icons/hash.svg',
                        height: 20,
                      ),
                    ),
                  ),
                  SizedBox(height: Sizes.height * 0.02),

                  TitleTextFeild(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SvgPicture.asset(
                        'assets/icons/hash.svg',
                        height: 20,
                        width: 20,
                      ),
                    ),
                    controller: confPasswordController,

                    hintText: "Enter Password Again",
                    titleText: "Confirm Password",
                  ),
                  SizedBox(height: Sizes.height * 0.04),
                  defaultButton(
                    buttonColor: AppColor.blue,
                    onTap: () {
                      verifyOtp();
                    },
                    height: 45,
                    width: double.infinity,
                    text: 'Save',
                  ),
                  SizedBox(height: Sizes.height * 0.02),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future verifyOtp() async {
    // Make the GET request
    final response = await ApiService.postData('otp/verify-otp', {
      "mobile": "otpMobileNo",
    });
    if (response['status'] == true) {
      // pushTo(CreatePassword(phoneNo: mobileNumberController.text.toString()));
      showCustomSnackbarSuccess(context, response['message']);
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }
}
