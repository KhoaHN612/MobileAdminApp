import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateUserNamePage extends StatefulWidget {
  @override
  _UpdateUserNamePageState createState() => _UpdateUserNamePageState();
}

class _UpdateUserNamePageState extends State<UpdateUserNamePage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();

  Future<void> _updateUserName() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString('userEmail');

      if (userEmail != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            doc.reference.update({'user_name': _userNameController.text});
          });
        });

        await prefs.setString('userName', _userNameController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User name updated successfully')),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update User Name')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _userNameController,
                  decoration: InputDecoration(labelText: 'New User Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your new user name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateUserName,
                  child: Text('Update User Name'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}