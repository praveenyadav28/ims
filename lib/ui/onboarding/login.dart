import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/component/full_screen.dart';
import 'package:ims/model/company_model.dart';
import 'package:ims/ui/onboarding/forgot_password.dart';
import 'package:ims/ui/onboarding/utils/backgraound.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController licenceNoController = TextEditingController(
    text: "10001",
  );
  TextEditingController userIdController = TextEditingController(text: "Vijay");
  TextEditingController passwordController = TextEditingController(
    text: "Vijay@1234",
  );

  int selectedUserType = 0;
  BranchList? _selectedBranch;
  List<BranchList> branchList = [];

  @override
  void dispose() {
    licenceNoController.dispose();
    userIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingBackground(
        widget: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Welcome !",
                style: GoogleFonts.inter(
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff171A1F),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  "Please enter your credentials to access the system.",
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppColor.textColor,
                  ),
                ),
              ),
              _buildUserSwitch(),
              SizedBox(height: Sizes.height * 0.02),
              TitleTextFeild(
                titleText: "LICENSE NO.",
                hintText: "Enter License Number",
                controller: licenceNoController,
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SvgPicture.asset('assets/icons/hash.svg', height: 20),
                ),
              ),
              SizedBox(height: Sizes.height * 0.02),
              TitleTextFeild(
                titleText: "USER ID",
                hintText: "Enter User ID",
                controller: userIdController,
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SvgPicture.asset(
                    'assets/icons/userID.svg',
                    height: 20,
                  ),
                ),
              ),
              SizedBox(height: Sizes.height * 0.02),
              TitleTextFeild(
                titleText: "USER PASSWORD",
                hintText: "Enter Password",
                controller: passwordController,
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SvgPicture.asset(
                    'assets/icons/password.svg',
                    height: 20,
                  ),
                ),
              ),
              SizedBox(height: Sizes.height * 0.035),
              defaultButton(
                height: 40,
                width: double.infinity,
                text: "Log In",
                onTap: () {
                  getBranches();
                },
                buttonColor: AppColor.blue,
              ),

              SizedBox(height: Sizes.height * 0.04),
              if (selectedUserType == 0)
                InkWell(
                  onTap: () {
                    pushTo(ForgotPassword());
                  },
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColor.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                SizedBox(height: 16.5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSwitch() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(2, (index) {
        final isSelected = selectedUserType == index;
        return GestureDetector(
          onTap: () => setState(() => selectedUserType = index),
          child: Container(
            height: 40,
            margin: EdgeInsets.only(
              top: Sizes.height * .02,
              bottom: Sizes.height * .02,
              right: index == 0 ? 16 : 0,
            ),
            width: Sizes.width < 600 ? Sizes.width * 0.3 : 167,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selectedUserType == index ? AppColor.blue : AppColor.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              index == 0 ? "Admin" : "Employee",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColor.white : AppColor.black,
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> getBranches() async {
    try {
      var response = await ApiService.fetchData(
        licenceNoController.text.trim(),
        licenceNo: int.parse(licenceNoController.text.trim()),
      );

      if (response['status'] == true) {
        final data = response['data'];

        // ✅ Ensure data is a List before parsing
        if (data is List) {
          branchList = branchListFromJson(data);

          if (branchList.length == 1) {
            _selectedBranch = branchList.first;
            // Optionally trigger next step:
            postLogin();
          }
        } else {
          branchList = [BranchList.fromJson(data)];
          _selectedBranch = branchList.first;
        }

        setState(() {});
      } else {
        showCustomSnackbarError(context, response["message"]);
      }
    } catch (e, stack) {
      debugPrint("Error in getBranches: $e\n$stack");
      showCustomSnackbarError(
        context,
        "Something went wrong while fetching branches.",
      );
    }
  }

  Future postLogin() async {
    var response = await ApiService.postData(
      'user/login',
      {
        'licence_no': int.parse(licenceNoController.text.trim().toString()),
        'branch_id': _selectedBranch?.id,
        'username': userIdController.text.trim().toString(),
        'password': passwordController.text.trim().toString(),
      },
      licenceNo: int.parse(licenceNoController.text.trim().toString()),
    );
    if (response["status"] == true) {
      print(response);
      Preference.setString(PrefKeys.token, response['token']);
      Preference.setInt(
        PrefKeys.licenseNo,
        int.parse(licenceNoController.text.trim()),
      );
      Preference.setString(PrefKeys.locationId, response['user']['branch_id']);
      // Preference.setString(PrefKeys.rights, response['user']['rights']);
      showCustomSnackbarSuccess(context, response['message']);
      // await fetchAndSaveActiveSessionId();
      pushNdRemove(FullScreen());
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }

  Future<void> fetchAndSaveActiveSessionId() async {
    var response = await ApiService.fetchData(
      "session?licence_no=${Preference.getint(PrefKeys.licenseNo)}&branch_id=${_selectedBranch!.id}",
    );
    if (response["status"] == true) {
      List sessions = response['data'];
      for (var session in sessions) {
        if (session['is_active'] == 1) {
          await Preference.setInt(PrefKeys.sessionId, session['id']);
          await Preference.setString(
            PrefKeys.sessionDate,
            "${session['session_start_date']} - ${session['session_end_date']}",
          );
          break;
        }
      }
    }
  }
}
