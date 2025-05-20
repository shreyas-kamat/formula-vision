import 'package:flutter/material.dart';
import 'package:formulavision/auth/login_page.dart';
import 'package:formulavision/data/functions/auth.function.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formkey = GlobalKey<FormState>();

  bool _isObscure = true;

  TextEditingController otpController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmNewPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset Password',
                    style: GoogleFonts.lato(
                      fontSize: 35,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 50),
                  // Text(
                  //   'Email',
                  //   style: GoogleFonts.lato(
                  //     fontSize: 24,
                  //     color: Colors.white,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  // SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TextFormField(
                        controller: otpController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'One Time Password (OTP)',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "OTP Cannot be empty";
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: TextFormField(
                          obscureText: _isObscure,
                          controller: newPasswordController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                                icon: Icon(_isObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _isObscure = !_isObscure;
                                  });
                                }),
                            hintText: 'New Password',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          validator: (value) {
                            RegExp regex = RegExp(r'^.{6,}$');
                            if (value!.isEmpty) {
                              return "Password cannot be empty";
                            }
                            if (!regex.hasMatch(value)) {
                              return ("please enter valid password min. 6 character");
                            } else {
                              return null;
                            }
                          },
                          onChanged: (value) {},
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: TextFormField(
                          obscureText: _isObscure,
                          controller: newPasswordController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                                icon: Icon(_isObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _isObscure = !_isObscure;
                                  });
                                }),
                            hintText: 'Confirm New Password',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          validator: (value) {
                            RegExp regex = RegExp(r'^.{6,}$');
                            if (value!.isEmpty) {
                              return "Password cannot be empty";
                            }
                            if (!regex.hasMatch(value)) {
                              return ("please enter valid password min. 6 character");
                            } else {
                              return null;
                            }
                          },
                          onChanged: (value) {},
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 50),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formkey.currentState!.validate()) {
                          // Call the function to update the user configuration
                          resetPassword(context, widget.email,
                              otpController.text, newPasswordController.text);
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginPage()));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 80, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
