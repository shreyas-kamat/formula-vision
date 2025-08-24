import 'package:flutter/material.dart';
import 'package:formulavision/auth/resetpw_page.dart';
import 'package:formulavision/data/functions/auth.function.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formkey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();

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
                    'Forgot Password',
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
                        controller: emailController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Email Cannot be empty";
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  // SizedBox(height: 50),
                  // Text(
                  //   'Daily Limit',
                  //   style: GoogleFonts.lato(
                  //     fontSize: 24,
                  //     color: Colors.white,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  // SizedBox(height: 20),
                  // Container(
                  //   decoration: BoxDecoration(
                  //     color: Colors.grey.shade800,
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 16.0, vertical: 8.0),
                  //     child: TextFormField(
                  //       controller: dailyLimitController,
                  //       style: TextStyle(color: Colors.white),
                  //       decoration: InputDecoration(
                  //         hintText: 'Enter amount',
                  //         hintStyle: TextStyle(color: Colors.grey.shade500),
                  //         border: InputBorder.none,
                  //         enabledBorder: InputBorder.none,
                  //         focusedBorder: InputBorder.none,
                  //       ),
                  //       validator: (value) {
                  //         if (value!.isEmpty) {
                  //           return "Amount cannot be empty";
                  //         }
                  //         return null;
                  //       },
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: 50),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formkey.currentState!.validate()) {
                          // Call the function to update the user configuration
                          forgotPassword(context, emailController.text);
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ResetPasswordPage(
                                        email: emailController.text,
                                      )));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 80, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Update Configuration'),
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
