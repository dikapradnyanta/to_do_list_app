import 'package:flutter/material.dart';

WidgetBuilder getTestWidgetBuilder() {
  return (BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Test Page'),
        ),
        body: Center(
          child: Text(
            'This is a test widget',
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
      ),
    );
  };
}