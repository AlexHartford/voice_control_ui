import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ibm_watson_assistant/models.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:voice_control_ui/chatbot.dart';
import 'package:voice_control_ui/hybrid_widget.dart';

const WAKE_WORD = 'popcorn';
const PAUSE_DURATION = Duration(seconds: 1);

final ttsProvider = Provider<FlutterTts>((ref) => FlutterTts());

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
  String input;
  IbmWatsonAssistantResponse output;

  SpeechState({
    this.isListening = false,
    this.input = '',
    this.output,
  });
}

class SpeechHandler extends StateNotifier<SpeechState> {
  SpeechHandler(this.ref) : super(SpeechState()) {
    print('SpeechHandler init');
    // _listen();
  }

  final ProviderReference ref;

  static final provider = StateNotifierProvider<SpeechHandler>((ref) => SpeechHandler(ref));

  toggleListening() {
    state = SpeechState(
      isListening: !state.isListening,
      input: state.input,
      output: state.output,
    );
  }

  _listen() {
    final stt = ref.read(sttProvider)..listen(partialResults: true, pauseFor: PAUSE_DURATION);
    final stream = ref.read(sttStreamProvider.stream);
    final chatbot = ref.read(ChatbotService.provider);

    final tts = ref.read(ttsProvider);

    final hybrid = ref.read(HybridService.provider);

    stream.listen((event) async {
      print('event: ${event.eventType}');

      switch (event.eventType) {
        case SpeechRecognitionEventType.finalRecognitionEvent:
          if (event.recognitionResult.recognizedWords.contains(WAKE_WORD) || state.isListening) {
            final input = event.recognitionResult.recognizedWords;
            state = SpeechState(
              isListening: false,
              input: input,
              output: state.output,
            );
            // TODO: Add some sort of loading indicator
            final output = await chatbot.sendInput(input);
            state = SpeechState(
              isListening: state.isListening,
              input: state.input,
              output: output,
            );
            switch (output.output.intents.first.intent) {
              case 'add_food':
                hybrid.trigger('ADD');
                break;
              case 'search':
                hybrid.trigger('SEARCH');
                break;
              case 'test':
                hybrid.trigger('TEST_PAGE');
                break;
              case 'remove_food':
                hybrid.trigger('REMOVE');
                break;
              default:
                break;
            }
            await tts.speak(output.responseText);
          }
          stt.listen(partialResults: true, pauseFor: PAUSE_DURATION);
          break;
        case SpeechRecognitionEventType.partialRecognitionEvent:
          if (event.recognitionResult.recognizedWords.contains(WAKE_WORD) || state.isListening) {
            print('Waking up!!');
            state = SpeechState(
              isListening: true,
              input: event.recognitionResult.recognizedWords,
              output: state.output,
            );
          } else {
            print('Not waking up to: ${event.recognitionResult.recognizedWords}');
          }
          break;
        case SpeechRecognitionEventType.errorEvent:
          print('errorEvent: ${event.error}');
          stt.listen(partialResults: true, pauseFor: PAUSE_DURATION);
          break;
        case SpeechRecognitionEventType.statusChangeEvent:
          print('Status changed: ${event.isListening ? 'listening' : 'stopped'}');
          break;
        case SpeechRecognitionEventType.soundLevelChangeEvent:
          break;
      }
    });
  }
}
