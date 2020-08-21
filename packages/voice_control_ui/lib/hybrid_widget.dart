import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Hybrid extends HookWidget {
  const Hybrid({
    @required this.key,
    @required this.child,
    @required this.onSelect,
  }) : super(key: key);

  final ValueKey<String> key;
  final Widget child;
  final Function onSelect;

  @override
  Widget build(BuildContext context) {
    final service = useProvider(HybridService.provider);
    service.register(key.value, onSelect);
    return child;
  }
}

class HybridService {
  final Map<String, Function> _register;

  HybridService() : _register = Map();

  static final provider = Provider<HybridService>((_) => HybridService());

  register(String key, Function onSelect) => _register[key] = onSelect;

  trigger(String key) {
    print('HybridWidget Triggered - Key: $key - Value: ${_register[key]}');
    return _register[key]();
  }
}
