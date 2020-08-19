import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';
import 'package:voice_control_ui/chatbot.dart';

final sttProvider = Provider<SpeechToTextProvider>((_) => SpeechToTextProvider(SpeechToText()));

final sttInitProvider =
    FutureProvider<bool>((ref) async => await ref.watch(sttProvider).initialize());

final sttStreamProvider = StreamProvider.autoDispose<SpeechRecognitionEvent>((ref) {
  final stt = ref.watch(sttProvider);
  if (stt.isAvailable) {
    debugPrint('Initialized speech-to-text stream');
    return stt.stream;
  } else {
    throw Exception('Failed to initialize speech-to-text stream');
  }
});

final listeningProvider = StateProvider<bool>((_) => false);

final lastFinishedProvider = StateProvider<String>((_) => 'N/A');

final lastResponseProvider = StateProvider<String>((_) => 'No response yet');

final test = Provider<void>((ref) async {
  print('testprovider');
  final stream = ref.watch(sttStreamProvider.stream);
  final listening = ref.watch(listeningProvider);
  final lastFinished = ref.watch(lastFinishedProvider);
  final lastResponse = ref.watch(lastResponseProvider);
  final chatbot = ref.watch(ChatbotService.provider);
  final stt = ref.watch(sttProvider)..listen(partialResults: true);

  stream.listen((event) async {
    print('event: ${event.eventType}');
    switch (event.eventType) {
      case SpeechRecognitionEventType.finalRecognitionEvent:
        if (event.recognitionResult.recognizedWords.contains('popcorn')) {
          listening.state = false;
          lastFinished.state = event.recognitionResult.recognizedWords;
          lastResponse.state = await chatbot.sendInput(lastFinished.state);
        }
        stt.listen(partialResults: true);
        break;
      case SpeechRecognitionEventType.partialRecognitionEvent:
        if (event.recognitionResult.recognizedWords.contains('popcorn') && !listening.state) {
          listening.state = true;
          print('Waking up!!');
        } else if (listening.state) {
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
});

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
              Container(
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
                          CurrentText(),
                          FinalText(),
                          ResponseText(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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

class ResponseText extends HookWidget {
  const ResponseText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = useProvider(lastResponseProvider).state;

    return Container(
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class FinalText extends HookWidget {
  const FinalText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = useProvider(lastFinishedProvider).state;
    useProvider(test);

    return Container(
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
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

class CurrentText extends HookWidget {
  const CurrentText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stream = useProvider(sttStreamProvider);

    return stream.when(
      data: (data) {
        return Text(
          data.recognitionResult != null ? data.recognitionResult.recognizedWords : '',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        );
      },
      loading: () => Text(
        '...',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
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
