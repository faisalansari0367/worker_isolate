<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

Long running isolate to keep the heavy work off from UI thread.


## Usage

```dart
final worker = Worker();
final result = await worker.compute(jsonDecode, jsonString);

```

## Additional information

You can use this package to decodeJson, parseJson, for base64Decoding and encoding and so on.
this package will help you to achieve more smooth ui because it will handle all the heavy work in the background.

