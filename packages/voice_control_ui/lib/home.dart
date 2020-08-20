import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:voice_control_ui/chatbot.dart';

final sttProvider = Provider<SpeechToTextProvider>((_) => SpeechToTextProvider(SpeechToText()));

final sttInitProvider =
    FutureProvider<bool>((ref) async => await ref.watch(sttProvider).initialize());

final sttStreamProvider = StreamProvider<SpeechRecognitionEvent>((ref) {
  final stt = ref.watch(sttProvider);
  if (stt.isAvailable) {
    debugPrint('Initialized speech-to-text stream');
    return stt.stream;
  } else {
    throw Exception('Failed to initialize speech-to-text stream');
  }
});

class SpeechState {
  bool isListening;
  String previousInput;
  String previousOutput;
  String currentInput;

  SpeechState({
    this.isListening = false,
    this.previousInput = '',
    this.previousOutput = '',
    this.currentInput = '',
  });
}

class SpeechHandler extends StateNotifier<SpeechState> {
  SpeechHandler(this.ref) : super(SpeechState()) {
    print('SpeechHandler init');
    _listen();
  }

  final ProviderReference ref;

  static final provider = StateNotifierProvider<SpeechHandler>((ref) => SpeechHandler(ref));

  toggleListening() {
    state = SpeechState(
      isListening: !state.isListening,
      currentInput: state.currentInput,
      previousInput: state.previousInput,
      previousOutput: state.previousOutput,
    );
  }

  _listen() {
    final stt = ref.read(sttProvider)..listen(partialResults: true);
    final stream = ref.read(sttStreamProvider.stream);
    final chatbot = ref.read(ChatbotService.provider);
    print('listening');

    stream.listen((event) async {
      print('event: ${event.eventType}');

      switch (event.eventType) {
        case SpeechRecognitionEventType.finalRecognitionEvent:
          if (event.recognitionResult.recognizedWords.contains('popcorn')) {
            state = SpeechState(
              isListening: false,
              previousInput: event.recognitionResult.recognizedWords,
              previousOutput: await chatbot.sendInput(state.previousOutput),
              currentInput: state.currentInput,
            );
          }
          stt.listen(partialResults: true);
          break;
        case SpeechRecognitionEventType.partialRecognitionEvent:
          if (event.recognitionResult.recognizedWords.contains('popcorn') && !state.isListening) {
            state = SpeechState(
              isListening: true,
              previousInput: state.previousInput,
              previousOutput: state.previousOutput,
              currentInput: event.recognitionResult.recognizedWords,
            );
            print('Waking up!!');
          } else if (state.isListening) {
            print('Woke up from button press');
          } else {
            print('Not waking up to: ${event.recognitionResult.recognizedWords}');
          }
          break;
        case SpeechRecognitionEventType.errorEvent:
          print('errorEvent: ${event.error}');
          stt.listen(partialResults: true);
          break;
        case SpeechRecognitionEventType.statusChangeEvent:
          print('Status changed: ${event.isListening ? 'listening' : 'stopped'}');
          // if (!event.isListening) stt.listen(partialResults: true);
          break;
        case SpeechRecognitionEventType.soundLevelChangeEvent:
          break;
      }
    });
  }
}

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
      data: (_) {
        return Stack(
          children: [
            TabBarView(
              controller: controller,
              children: [
                Container(
                  child: Center(
                    child: Text('Scan'),
                  ),
                ),
                SpeechDisplay(),
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
        );
      },
    );
  }
}

class SpeechDisplay extends HookWidget {
  const SpeechDisplay({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final speech = useProvider(SpeechHandler.provider.state);

    return Container(
      child: Center(
        child: Card(
          color: Colors.grey[600].withOpacity(0.75),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  speech.currentInput,
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  speech.previousInput,
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  speech.previousOutput,
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivateVoiceButton extends HookWidget {
  const ActivateVoiceButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width;
    // final listening = useProvider(listeningProvider).state;
    final listening = useProvider(SpeechHandler.provider.state).isListening;

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
          // onTap: () => context.read(listeningProvider).state ^= true,
          onTap: () => context.read(SpeechHandler.provider).toggleListening(),
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
    // final stopped = useState(false);

    // useEffect(() {
    //   context.read(listeningProvider).addListener((state) async {
    //     while (state) {
    //       try {
    //         stopped.value = !stopped.value;
    //       } catch (e) {
    //         break;
    //       }
    //       await Future.delayed(const Duration(milliseconds: 250));
    //     }
    //   });
    //   return;
    // }, const []);

    return ListView.separated(
      itemCount: (fullWidth / (SoundWaves.barWidth + SoundWaves.spaceWidth)).ceil(),
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, int index) {
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            color: Colors.white,
            height: SoundWaves.barHeight + rng.nextInt(75),
            // height: stopped.value
            //     ? SoundWaves.barHeight + rng.nextInt(75)
            //     : SoundWaves.barHeight + rng.nextInt(75),
            width: SoundWaves.barWidth,
          ),
        );
      },
      separatorBuilder: (_, __) => SizedBox(width: SoundWaves.spaceWidth),
    );
  }
}
