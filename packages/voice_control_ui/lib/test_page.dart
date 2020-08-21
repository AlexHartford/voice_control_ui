import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TestPage extends HookWidget {
  const TestPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TEST_PAGE'),
        backgroundColor: Colors.green[300],
      ),
      body: Container(
        color: Colors.green[300],
      ),
    );
  }
}
