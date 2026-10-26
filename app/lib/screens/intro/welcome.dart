import 'package:crypto_matrix/constants.dart';
import 'package:flutter/material.dart';
import 'package:crypto_matrix/widgets/adaptive.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Column(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.only(top: 100, bottom: 30),
                child: Image.asset('assets/coins/ltc.png')),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Welcome to Crypto Matrix',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                )),
            Padding(
                padding:
                    EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 80),
                child: Text(
                  'Show live crypto prices and charts on your LED matrix. Connect your phone to your Crypto Matrix to get started.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                )),
            AdaptiveTextButton(
                child: Text(
                  'Get started',
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(
                      context, RouteNames.INTRO_BLUETOOTH);
                })
          ],
        )));
  }
}
