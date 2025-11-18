import 'package:flutter/material.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomHeader(),
    body: Column(
      children: [
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Próximamente nuevas funcionalidades',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}