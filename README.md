# Easy Autocomplete with Objects

Based on [Easy Autocomplete by 4inka](https://github.com/4inka/flutter_easy_autocomplete) this flutter widget handles input autocomplete suggestions for generic types items.
Suggestions are given as a List of objet or as a Future (asyncSuggestions).

# Preview

# Why a new package
The changes I made are breaking some properties and behaviour of the original package. This is why I decided not to pollute it but create a new one.
If you need to handle autocomplete for simple strings, use [Easy Autocomplete](https://pub.dev/packages/easy_autocomplete); if you want to autocomplete items of any type, choose **Easy Autocomplete with Objects** 

# Example
```dart
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
                          suggestionsStartWith: true,
                          suggestions: [
                            MyObject(value: 1, text: 'one'),
                            MyObject(value: 2, text: 'two'),
                            MyObject(value: 3, text: 'three'),
                            MyObject(value: 4, text: 'four'),
                            MyObject(value: 5, text: 'five'),
                            MyObject(value: 6, text: 'six'),
                            MyObject(value: 7, text: 'seven'),
                            MyObject(value: 8, text: 'eight'),
                            MyObject(value: 9, text: 'nine'),
                            MyObject(value: 10, text: 'ten'),
                          ],
                          onChangeSelection: (value) => debugPrint('onChangeSelection value: ${value?.value ?? -1}'),
                          itemAsString: (p0) => p0?.text ?? '',
                          compareFn: (p0, p1) => p0?.value == p1?.value,
                        )),
                  ],
                )
              )
            )
      );
  }
  ```