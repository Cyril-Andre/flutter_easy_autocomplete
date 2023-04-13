# Easy Autocomplete with Objects

Based on [Easy Autocomplete by 4inka](https://github.com/4inka/flutter_easy_autocomplete) this flutter widget handles input autocomplete suggestions for generic types items.
Suggestions are given as a List of objet or as a Future (asyncSuggestions).

# Preview

# Why a new package
The changes I made are breaking some properties and behaviour of the original package. This is why I decided not to pollute it but create a new one.
If you need to handle autocomplete for simple strings, use [Easy Autocomplete](https://pub.dev/packages/easy_autocomplete); if you want to autocomplete items of any type, choose **Easy Autocomplete with Objects** 