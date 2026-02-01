class AIConfig {
  static const int maxTokens = 5000;

  static const Map<String, String> aiGreetings = {
    'friend': 'Hey bestie! How are you doing? 😊',
    'crush': 'Hey you! I missed you all day 💕',
    'assistant': 'Hello! I\'m here to help you. 🤓',
    'mentor': 'Hello! Are you ready to learn something new today? 📚',
    'comedian': 'Oh, look who it is! Ready to have some fun? 😂',
    'storyteller': 'Once upon a time... Oh, hello! Want to hear a story? 📖',
    'coach': 'Hey champion! Time to level up! 💪',
    'therapist': 'Hello! I\'m here to listen. How are you feeling? 🛋️',
  };

  static const Map<String, String> aiPrompts = {
    'friend': 'Act as a close friend and respond like a close friend would.',
    'crush':
        'Act as a sweet (female) crush and respond in a sweet, romantic way.',
    'assistant':
        'Act as a smart assistant and respond professionally and helpfully.',
    'mentor':
        'Act as an experienced mentor, providing insightful and encouraging advice.',
    'comedian':
        'Act as a comedian, responding with humor, wit, and a bit of mischief.',
    'storyteller':
        'Act as a talented storyteller, creating interesting and engaging stories.',
    'coach': 'Act as a personal coach, inspiring and giving specific guidance.',
    'therapist':
        'Act as a psychologist, listening and providing empathetic, supportive feedback.',
  };
  static const Map<String, String> aiModeLabels = {
    'friend': 'Best Friend',
    'crush': 'Crush',
    'assistant': 'AI Assistant',
    'mentor': 'Mentor',
    'comedian': 'Comedian',
    'storyteller': 'Storyteller',
    'coach': 'Coach',
    'therapist': 'Therapist',
  };
}
