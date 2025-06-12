import 'dart:ffi';
import 'package:ffi/ffi.dart'; // ✅ supaya Pointer<Utf8> bisa dipakai

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
