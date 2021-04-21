# hello_me

A new Flutter application.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Ex1:
Q1: The class being used to implement controller pattern in this library is SnappingSheetController class.
It allows the developer to control features such as: setting the position of the snapping sheet using setSnappingSheetFactor/setSnappingSheetPosition,
snap to a given snapping position using snapToPosition, stop the current snapping using stopCurrentSnapping.

Q2:The parameter in charge is: snappingPositions, which takes in a list of SnappingPosition.factor or SnappingPosition.pixels.

Q3: InkWell advantage: the user can see ink spreading as a response to his touch, so the user gets an indication and reaction from the app.
GestureDetector advantage: it fits it size according to the parents or child sizing behavior, whereas InkWell
will not properly update to conform to changes if the size of its underlying Material - InkWell is not a good choice when using Material widgets that are changing size.
