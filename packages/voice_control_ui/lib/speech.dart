import 'package:flutter/material.dart';
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