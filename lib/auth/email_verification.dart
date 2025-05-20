import 'package:flutter/material.dart';
import 'package:formulavision/auth/login_page.dart';
import 'package:formulavision/data/functions/auth.function.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  const EmailVerificationPage({super.key, required this.email});

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _formkey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    verifyEmail(context, widget.email);
  }

  TextEditingController currentBalanceController = TextEditingController();
  TextEditingController dailyLimitController = TextEditingController();

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
                    'Email Verification',
                    style: GoogleFonts.lato(
                      fontSize: 35,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 50),
                  Text(
                    'Email will be sent to',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade700.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Text(widget.email,
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                color: Colors.white,
                              )),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 50), // Add some space before the button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 80, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue to Login'),
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
