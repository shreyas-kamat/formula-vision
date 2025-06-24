import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:formulavision/auth/login_page.dart';
import 'package:formulavision/data/functions/auth.function.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  _RegisterPageState();

  bool showProgress = false;
  bool visible = false;

  final _formkey = GlobalKey<FormState>();
  // final _auth = FirebaseAuth.instance;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpassController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  late FixedExtentScrollController gradeController;
  bool _isObscure = true;
  var options = [
    'Student',
    'Teacher',
  ];
  final _currentItemSelected = "Student";
  var role = "Student";

  String grade = 'Grade';

  final items = ['Grade', 'XI', 'XII', 'Super', 'Admin'];

  int index = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    gradeController = FixedExtentScrollController(initialItem: index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              SingleChildScrollView(
                child: Form(
                  key: _formkey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Hello There!',
                          style: GoogleFonts.pacifico(
                              fontSize: 52, color: Colors.white)),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Register below with your Details!  ",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      SizedBox(height: 50),
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
                              controller: firstNameController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'First Name',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "First Name cannot be empty";
                                }
                                return null;
                              },
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
                              controller: lastNameController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Last Name',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Last Name cannot be empty";
                                }
                                return null;
                              },
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
                              controller: usernameController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Username',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Username cannot be empty";
                                }
                                return null;
                              },
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
                              controller: emailController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Email cannot be empty";
                                }
                                return null;
                              },
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
                              controller: passwordController,
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
                                hintText: 'Password',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
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
                              controller: confirmpassController,
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
                                hintText: 'Confirm Password',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 15),
                        child: visible
                            ? AnimatedOpacity(
                                opacity: visible ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 500),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        visible = false;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(232, 76, 104, 1),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: () {
                                  setState(() {
                                    visible = true;
                                  });
                                  if (_formkey.currentState!.validate()) {
                                    register(
                                        context,
                                        firstNameController.text,
                                        lastNameController.text,
                                        usernameController.text,
                                        emailController.text,
                                        passwordController.text);
                                  }
                                },
                                child: Ink(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.shade700,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                      child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  )),
                                ),
                              ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginPage()));
                            },
                            child: Text(
                              ' Login',
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPicker() => SizedBox(
        height: 300,
        child: CupertinoPicker(
          scrollController: gradeController,
          itemExtent: 64,
          selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
            background: Color.fromARGB(255, 189, 54, 54).withOpacity(0.2),
          ),
          children: items
              .map((item) => Center(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 25),
                    ),
                  ))
              .toList(),
          onSelectedItemChanged: (index) {
            setState(() {
              this.index = index;
              grade = items[index];
            });
            final item = items[index];
          },
        ),
      );
}
