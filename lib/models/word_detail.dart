class WordDetail {
  const WordDetail({
    required this.word,
    required this.hindiMeaning,
    required this.synonyms,
    required this.antonyms,
    required this.wordForms,
    required this.explanation,
  });

  final String word;
  final String hindiMeaning;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> wordForms;
  final String explanation;

  factory WordDetail.fromJson(Map<String, dynamic> json) {
    return WordDetail(
      word: json['word'] as String? ?? '',
      hindiMeaning: json['hindiMeaning'] as String? ?? '',
      synonyms: _stringList(json['synonyms']),
      antonyms: _stringList(json['antonyms']),
      wordForms: _stringList(json['wordForms']),
      explanation: json['explanation'] as String? ?? '',
    );
  }

  factory WordDetail.fromWordData(String word, Map<String, dynamic> json) {
    return WordDetail(
      word: word,
      hindiMeaning: json['hindi'] as String? ?? '',
      synonyms: _stringList(json['synonyms']),
      antonyms: _stringList(json['antonyms']),
      wordForms: _stringList(json['forms']),
      explanation: json['explanation'] as String? ?? '',
    );
  }

  factory WordDetail.basic(String word) {
    return WordDetail(
      word: word,
      hindiMeaning: '',
      synonyms: const [],
      antonyms: const [],
      wordForms: [word],
      explanation: '',
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return (value as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}
