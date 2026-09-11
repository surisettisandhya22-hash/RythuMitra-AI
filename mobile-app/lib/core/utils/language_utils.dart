class LanguageUtils {
  /// Maps a short language code (e.g., 'te') to a speech/TTS locale (e.g., 'te-IN')
  static String getLocaleForLanguage(String languageId) {
    switch (languageId) {
      case 'te':
        return 'te-IN';
      case 'hi':
        return 'hi-IN';
      case 'ta':
        return 'ta-IN';
      case 'kn':
        return 'kn-IN';
      case 'ml':
        return 'ml-IN';
      case 'mr':
        return 'mr-IN';
      case 'bn':
        return 'bn-IN';
      case 'gu':
        return 'gu-IN';
      case 'pa':
        return 'pa-IN';
      case 'en':
      default:
        return 'en-IN';
    }
  }

  /// Maps a short language code to a full display name
  static String getLanguageName(String languageId) {
    switch (languageId) {
      case 'te':
        return 'Telugu';
      case 'hi':
        return 'Hindi';
      case 'ta':
        return 'Tamil';
      case 'kn':
        return 'Kannada';
      case 'ml':
        return 'Malayalam';
      case 'mr':
        return 'Marathi';
      case 'bn':
        return 'Bengali';
      case 'gu':
        return 'Gujarati';
      case 'pa':
        return 'Punjabi';
      case 'en':
      default:
        return 'English';
    }
  }
}
