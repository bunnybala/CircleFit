import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState {
  final String val;
  MyState(this.val);
}

// Test 1: Notifier family
class MyNotifier extends FamilyNotifier<MyState, int> {
  @override
  MyState build(int arg) => MyState('hello $arg');
}
final myProvider = NotifierProvider.family<MyNotifier, MyState, int>(MyNotifier.new);

// Test 2: AsyncNotifier family
class MyAsyncNotifier extends FamilyAsyncNotifier<MyState, int> {
  @override
  Future<MyState> build(int arg) async => MyState('hello $arg');
}
final myAsyncProvider = AsyncNotifierProvider.family<MyAsyncNotifier, MyState, int>(MyAsyncNotifier.new);
