import 'package:easy_autocomplete/easy_autocomplete.dart';
import 'package:example/model/object.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Example',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: SafeArea(
            child: Scaffold(
                appBar: AppBar(title: Text('Example')),
                body: Column(
                  children: [
                    Container(
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        child: EasyAutocomplete<MyObject>(
                          suggestions: [MyObject(value: 1, text: "one"), MyObject(value: 2, text: "two"), MyObject(value: 3, text: "three"), MyObject(value: 4, text: "four")],
                          onChangeSelection: (value) => print('onSubmitted value: ${value?.value ?? -1}'),
                          itemAsString: (p0) => p0?.text ?? '',
                          compareFn: (p0, p1) => p0?.value == p1?.value,
                        )),
                    TextField()
                  ],
                ))));
  }
}
