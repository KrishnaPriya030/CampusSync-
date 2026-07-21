import "package:flutter/material.dart";

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        backgroundColor: const Color.fromARGB(255, 51, 15, 150),
        foregroundColor: Colors.white,
        title: const Text('Login'),
      ),
      body: Padding(
  padding: const EdgeInsets.all(24.0),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        'Welcome Back',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 10),

      const Text(
        'Login to continue to CampusSync',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),

      const SizedBox(height: 30),

      const TextField(
        decoration: InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email),
          border: OutlineInputBorder(),
        ),
      ),

      const SizedBox(height: 20),

      const TextField(
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: Icon(Icons.lock),
          border: OutlineInputBorder(),
        ),
      ),

      const SizedBox(height: 30),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style:ElevatedButton.styleFrom(
             backgroundColor: const Color.fromARGB(255, 51, 15, 150),
    foregroundColor: Colors.white,
  ),
          
          onPressed: () {
            // Backend login will be added later.
          },
          child: const Text('Login'),
        ),
      ),
    ],
  ),
),
    );
  }
}
