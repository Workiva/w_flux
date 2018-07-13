import 'package:w_flux/w_flux_server.dart';

class MyStore extends Store {
  final _fooMetadata = new Expando<String>();
  String getFooMetadata(StoreTriggerPayload payload) => _fooMetadata[payload];

  int _count = 0;
  int get count => _count;

  // ...

  void handleIncrementAction(_) {
    _count++;

    triggerWithPayload((payload) {
      _fooMetadata[payload] = '<payload added by handleIncrementAction>';
    });
  }
}

main() {
  var store = new MyStore();
  store.streamWithPayload.listen((payload) {
    final MyStore store = payload.store;
    print('Count: ${store.count}');
    print('Payload metadata: "${store.getFooMetadata(payload)}"');
  });

  // In a real use-case, this would be wired up to an action and not called directly.
  store.handleIncrementAction(null);
}
