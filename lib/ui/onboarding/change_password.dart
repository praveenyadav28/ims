import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ims/ui/onboarding/login.dart';
import 'package:ims/ui/onboarding/utils/backgraound.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/appbar.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class CreatePassword extends StatefulWidget {
  final String phoneNo;
  final String licenceNo;

  const CreatePassword({
    super.key,
    required this.phoneNo,
    required this.licenceNo,
  });

  @override
  State<CreatePassword> createState() => _CreatePasswordState();
}

class _CreatePasswordState extends State<CreatePassword> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> resetPassword() async {
    final response = await ApiService.postData("user/admin/update", {
      "licence_no": widget.licenceNo,
      "contact_no": widget.phoneNo,
      "password": passwordController.text,
    }, licenceNo: int.parse(widget.licenceNo));
    if (response['status'] == true) {
      showCustomSnackbarSuccess(context, response['message']);
      pushNdRemove(LoginScreen());
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingBackground(
        widget: Form(
          key: _formKey,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: AppbarClass(title: 'Change Password'),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TitleTextFeild(
                    controller: passwordController,
                    hintText: "New Password",
                    titleText: "New Password",
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Enter password";
                      }
                      if (value.length < 6) {
                        return "Password must be 6 characters";
                      }
                      return null;
                    },
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SvgPicture.asset(
                        'assets/icons/password.svg',
                        height: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TitleTextFeild(
                    controller: confirmPasswordController,
                    hintText: "Confirm Password",
                    titleText: "Confirm Password",
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: SvgPicture.asset(
                        'assets/icons/password.svg',
                        height: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value != passwordController.text) {
                        return "Password not match";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  defaultButton(
                    buttonColor: AppColor.blue,
                    text: "Submit",
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        resetPassword();
                      }
                    },
                    width: double.infinity,
                    height: 45,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
