import 'package:flutter/material.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 51, 15, 150),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(Icons.event_seat_sharp, size: 100, color: Colors.white),

            SizedBox(height: 20),

            Text(
              "CampusSync",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 219, 209, 209),
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Smart Campus Event Management",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),

            SizedBox(height: 30),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(
                Icons.arrow_forward,
                color:Colors.white,
                size:35
              ),
            ),
          ],
        ),
      ),
    );
  }
}
