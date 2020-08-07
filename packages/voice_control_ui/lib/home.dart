import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Home extends HookWidget {
  const Home({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: ActivateVoiceButton(),
          )
        ],
      ),
    );
  }
}

final listeningProvider = StateProvider<bool>((_) => false);

class ActivateVoiceButton extends HookWidget {
  const ActivateVoiceButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width;
    final listening = useProvider(listeningProvider).state;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.only(bottom: listening ? 0 : 16),
      child: Card(
        elevation: 8,
        color: Colors.blueAccent,
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(listening ? 0 : 25),
          ),
        ),
        child: InkWell(
          onTap: () => context.read(listeningProvider).state ^= true,
          borderRadius: BorderRadius.all(
            Radius.circular(listening ? 0 : 25),
          ),
          splashColor: Colors.white70,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: listening ? 100 : 50,
            width: listening ? fullWidth : 100,
            child: listening
                ? SoundWaves()
                : Icon(
                    Icons.mic,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}

class SoundWaves extends HookWidget {
  SoundWaves({Key key}) : super(key: key);

  static const double barWidth = 3;
  static const double barHeight = 5;
  static const double spaceWidth = 2;

  final rng = Random();

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width;
    final test = useState(false);

    useEffect(() {
      context.read(listeningProvider).addListener((state) async {
        while (state) {
          try {
            test.value = !test.value;
          } catch (e) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 250));
        }
      });
      return;
    }, const []);

    return ListView.separated(
      itemCount: (fullWidth / (SoundWaves.barWidth + SoundWaves.spaceWidth)).ceil(),
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, int index) {
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            color: Colors.white,
            height: test.value
                ? SoundWaves.barHeight + rng.nextInt(75)
                : SoundWaves.barHeight + rng.nextInt(75),
            width: SoundWaves.barWidth,
          ),
        );
      },
      separatorBuilder: (_, __) => SizedBox(width: SoundWaves.spaceWidth),
    );
  }
}
