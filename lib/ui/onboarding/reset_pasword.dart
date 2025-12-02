import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController licenceNoController = TextEditingController();
  bool otpvarify = false;
  final _formKey = GlobalKey<FormState>();

  //resendOtp
  int _start = 0; // Timer duration in seconds
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _start = 30; // Reset timer duration
      _timer?.cancel(); // Cancel any existing timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_start > 0) {
            _start--;
          } else {
            _timer?.cancel(); // End timer
          }
        });
      });
    });
  }

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
                child: AppbarClass(title: 'Forgot Password'),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: Sizes.height * .04),
                  TitleTextFeild(
                    titleText: "LICENSE NO.",
                    hintText: "Enter License Number",
                    controller: licenceNoController,
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
                        'assets/icons/contact.svg',
                        height: 20,
                        width: 20,
                      ),
                    ),
                    controller: mobileNumberController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Please enter Mobile Number";
                      } else if (mobileNumberController.text.length != 10) {
                        return "Please enter valid number";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    hintText: "Enter Mobile Number",
                    titleText: "MOBILE NUMBER",
                    maxLength: 10,
                    suffixIcon: TextButton(
                      onPressed: _start > 0
                          ? null
                          : () async {
                              await getSignupUsersDetails();
                            },
                      child: Text(
                        _start > 0 ? '$_start sec' : 'Send OTP',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Sizes.height * 0.02),
                  !otpvarify
                      ? Container()
                      : TitleTextFeild(
                          keyboardType: TextInputType.number,
                          controller: otpController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please enter OTP";
                            }
                            return null;
                          },
                          titleText: "OTP",
                          hintText: "Enter OTP",
                        ),
                  SizedBox(height: Sizes.height * 0.04),

                  defaultButton(
                    onTap: () {
                      if (_formKey.currentState!.validate() &&
                          otpvarify == true) {
                        verifyOtp(mobileNumberController.text, context);
                      }
                    },
                    height: 45,
                    width: Sizes.width < 850
                        ? Sizes.width * .5
                        : Sizes.width * .2,
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

  Future sendOtp(String otpMobileNo, BuildContext context) async {
    final response = await ApiService.postData('otp/send-otp', {
      "mobile": otpMobileNo,
    });
    if (response['status'] == true) {
      otpvarify = true;
      showCustomSnackbarSuccess(context, response['message']);
    } else {
      otpvarify = false;
      showCustomSnackbarError(context, response['message']);
    }
  }

  Future verifyOtp(String otpMobileNo, BuildContext context) async {
    // Make the GET request
    final response = await ApiService.postData('otp/verify-otp', {
      "mobile": otpMobileNo,
      'otp': otpController.text.toString(),
    });
    if (response['status'] == true) {
      // pushTo(CreatePassword(phoneNo: mobileNumberController.text.toString()));
      showCustomSnackbarSuccess(context, response['message']);
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }

  Future<void> getSignupUsersDetails() async {
    try {
      final response = await ApiService.postData(
        "getlicencebycontect",
        {
          "licence_no": licenceNoController.text.toString(),
          "contact_no": mobileNumberController.text.toString(),
        },
        licenceNo: int.parse(licenceNoController.text.toString()),
      );
      if (response != null && response['status'] == true) {
        sendOtp(mobileNumberController.text, context);
        _startResendTimer(); // Start the timer after sending OTP
      } else {
        showCustomSnackbarError(context, response['message']);
      }
    } catch (e) {
      debugPrint("Error loading users: $e");
    }
  }
}
