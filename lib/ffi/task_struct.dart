import 'dart:ffi';
import 'package:ffi/ffi.dart';

/// native struct for Task
/// same as the C struct
final class NativeTask extends Struct {
  @Int32()
  external int id;

  external Pointer<Utf8> title;
  external Pointer<Utf8> description;

  @Int32()
  external int timestamp;

  @Int32()
  external int isComplete;

  @Int32()
  external int isDeleted;

  external Pointer<Utf8> category;
}

/// Extension to convert NativeTask to Dart Map
extension NativeTaskExtension on NativeTask {
  /// Convert NativeTask to Dart Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title.toDartString(),
      'description': description.toDartString(),
      'timestamp': timestamp,
      'isComplete': isComplete == 1,
      'isDeleted': isDeleted == 1,
      'category': category.toDartString(),
    };
  }
}