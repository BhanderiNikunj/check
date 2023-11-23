import 'package:check/custom_drop_down.dart' as cs;
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int value1 = 0;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Align(
          alignment: Alignment.center,
          child: cs.CustomDropdownButton(
            alignment: Alignment.center,
            autofocus: true,
            hint: Text("Hello"),
            dropdownColor: Colors.amber,
            list: [
              cs.CustomDropdownMenuItem(
                value: 0,
                child: Container(
                  height: 50,
                  width: 100,
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("100"),
                      Text("GM"),
                    ],
                  ),
                ),
              ),
              cs.CustomDropdownMenuItem(
                value: 1,
                child: Container(
                  height: 50,
                  width: 100,
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("200"),
                      Text("GM"),
                    ],
                  ),
                ),
              ),
              cs.CustomDropdownMenuItem(
                value: 2,
                child: Container(
                  height: 50,
                  width: 100,
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("300"),
                      Text("GM"),
                    ],
                  ),
                ),
              ),
            ],
            selectedValue: value1,
            onChanged: (value) {
              value1 = value!;
              setState(() {});
            },
          ),
        ),
      ),
    );
  }
}
