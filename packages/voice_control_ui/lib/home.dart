import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

final sttProvider = Provider<SpeechToTextProvider>((_) => SpeechToTextProvider(SpeechToText()));

final sttInitProvider =
    FutureProvider<bool>((ref) async => await ref.read(sttProvider).initialize());

final listeningProvider = StateProvider<bool>((_) => false);

class Home extends HookWidget {
  const Home({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = useTabController(initialLength: 3, initialIndex: 1);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hybrid UI Demo'),
        centerTitle: true,
        bottom: TabBar(
          controller: controller,
          tabs: [
            Tab(key: PageStorageKey('Scan'), text: 'Scan'),
            Tab(key: PageStorageKey('Home'), text: 'Home'),
            Tab(key: PageStorageKey('Search'), text: 'Search'),
          ],
        ),
      ),
      body: TabViews(controller),
    );
  }
}

class TabViews extends HookWidget {
  const TabViews(this.controller, {Key key}) : super(key: key);

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final sttAvailable = useProvider(sttInitProvider);

    return sttAvailable.when(
      loading: () => Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Speech recognition not available.\n$err',
        ),
      ),
      data: (_) => Stack(
        children: [
          TabBarView(
            controller: controller,
            children: [
              Container(
                child: Center(
                  child: Text('Scan'),
                ),
              ),
              // Container(
              //   child: Center(
              //     child: Text('Home'),
              //   ),
              // ),
              CurrentText(),
              Container(
                child: Center(
                  child: Text('Search'),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ActivateVoiceButton(),
          )
        ],
      ),
    );
  }
}

class ActivateVoiceButton extends HookWidget {
  const ActivateVoiceButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width;
    final listening = useProvider(listeningProvider).state;

    useEffect(() {
      final stt = context.read(sttProvider);
      context.read(listeningProvider).addListener((state) async {
        if (state) {
          stt.listen(partialResults: true);
          print('Listening');
        } else {
          if (stt.isListening) stt.stop();
          print('Not listening');
        }
      });
      return;
    }, const []);

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

final sttStreamProvider = StreamProvider.autoDispose<SpeechRecognitionEvent>((ref) {
  final stt = ref.read(sttProvider);
  if (stt.isAvailable) {
    print('init');
    return stt.stream;
  } else {
    print('Not init');
    return null;
  }
});

class CurrentText extends HookWidget {
  const CurrentText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stream = useProvider(sttStreamProvider);

    return stream.when(
      data: (data) => Center(
        child: Text(
          data.recognitionResult != null ? data.recognitionResult.recognizedWords : '',
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text(err),
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
    final stopped = useState(false);

    useEffect(() {
      context.read(listeningProvider).addListener((state) async {
        while (state) {
          try {
            stopped.value = !stopped.value;
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
            height: stopped.value
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
