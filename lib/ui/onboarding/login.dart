import 'dart:convert';

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
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController licenceNoController = TextEditingController();
  TextEditingController userIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool obscureText = true;
  BranchList? _selectedBranch;
  List<BranchList> branchList = [];
  @override
  void initState() {
    super.initState();

    rememberMe = Preference.getBool(PrefKeys.loginStatus);

    if (rememberMe) {
      licenceNoController.text = Preference.getString(PrefKeys.savedLicence);
      userIdController.text = Preference.getString(PrefKeys.savedUserId);
      passwordController.text = Preference.getString(PrefKeys.savedPassword);
    }
  }

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
              SizedBox(height: Sizes.height * 0.02),
              TitleTextFeild(
                titleText: "LICENSE NO.",
                hintText: "Enter License Number",
                controller: licenceNoController,
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Icon(Icons.receipt_long, size: 20),
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
                    'assets/icons/userId.svg',
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
                onFieldSubmitted: (value) {
                  getBranches();
                },
                obscureText: obscureText,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscureText = !obscureText;
                    });
                  },
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(height: Sizes.height * 0.02),
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (v) {
                      setState(() {
                        rememberMe = v ?? false;
                      });
                    },
                  ),
                  Text("Remember Me", style: GoogleFonts.inter(fontSize: 13)),
                ],
              ),
              SizedBox(height: Sizes.height * 0.02),
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
              ),
            ],
          ),
        ),
      ),
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

        if (data is List) {
          branchList = branchListFromJson(data);

          if (branchList.length == 1) {
            _selectedBranch = branchList.first;
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
    } catch (e) {
      showCustomSnackbarError(
        context,
        "Something went wrong while fetching your data.",
      );
    }
  }

  Future postLogin() async {
    try {
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
      print(response);
      if (response["status"] == true) {
        Preference.setBool(PrefKeys.loginStatus, rememberMe);
        if (rememberMe) {
          Preference.setString(PrefKeys.savedUserId, userIdController.text);
          Preference.setString(PrefKeys.savedPassword, passwordController.text);
          Preference.setString(PrefKeys.savedLicence, licenceNoController.text);
        } else {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove(PrefKeys.savedUserId);
          await prefs.remove(PrefKeys.savedPassword);
          await prefs.remove(PrefKeys.savedLicence);
        }
        Preference.setString(PrefKeys.token, response['token']);
        Preference.setInt(
          PrefKeys.loginTime,
          DateTime.now().millisecondsSinceEpoch,
        );
        Preference.setInt(
          PrefKeys.licenseNo,
          int.parse(licenceNoController.text.trim()),
        );
        Preference.setString(
          PrefKeys.rights,
          jsonEncode(response['user']['right_list']),
        );

        // single rights save
        Preference.setString(
          PrefKeys.singleRights,
          jsonEncode(response['user']['single_right']),
        );
        Preference.setString(
          PrefKeys.locationId,
          response['user']['branch_id'],
        );
        Preference.setString(
          PrefKeys.branchName,
          response['user']['branch_name'],
        );
        Preference.setString(
          PrefKeys.branchAddress,
          response['user']['address'],
        );
        Preference.setString(PrefKeys.state, response['user']['state']);
        Preference.setString(PrefKeys.userType, response['user']['role']);
        Preference.setString(
          PrefKeys.amcDueDate,
          DateFormat(
            'dd-MM-yyyy',
          ).format(DateTime.parse(response['user']['amc_due_date'])),
        );
        showCustomSnackbarSuccess(context, response['message']);
        // await fetchAndSaveActiveSessionId();
        pushNdRemove(FullScreen());
      } else {
        showCustomSnackbarError(context, response['message']);
      }
    } catch (e) {
      if (e is ApiException) {
        showCustomSnackbarError(context, e.message);
      }
    }
  }

  // Future<void> fetchAndSaveActiveSessionId() async {
  //   var response = await ApiService.fetchData(
  //     "session?licence_no=${Preference.getint(PrefKeys.licenseNo)}&branch_id=${_selectedBranch!.id}",
  //   );
  //   if (response["status"] == true) {
  //     List sessions = response['data'];
  //     for (var session in sessions) {
  //       if (session['is_active'] == 1) {
  //         await Preference.setInt(PrefKeys.sessionId, session['id']);
  //         await Preference.setString(
  //           PrefKeys.sessionDate,
  //           "${session['session_start_date']} - ${session['session_end_date']}",
  //         );
  //         break;
  //       }
  //     }
  //   }
  // }
}
