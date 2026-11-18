/// Primeiro ano em que os livros passam a ser separados por mês.
const int kFirstMonthlyYear = 2027;

const List<String> kMonthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

class Book {
  final String id;
  String title;
  String author;
  String? coverUrl;

  /// Nota de 0 a 5, em passos de 0,5.
  double rating;

  /// "5 estrelas especial": só vale quando a nota é 5 (estrelas azuis).
  bool special;

  /// Ano e mês da leitura. Nulos = "lidos antes de 2027".
  int? readYear;
  int? readMonth;

  DateTime addedAt;

  Book({
    required this.id,
    required this.title,
    this.author = '',
    this.coverUrl,
    this.rating = 0,
    this.special = false,
    this.readYear,
    this.readMonth,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  bool get isLegacy =>
      readYear == null || readMonth == null || readYear! < kFirstMonthlyYear;

  bool get isSpecial => special && rating >= 5;

  /// Chave de ordenação do mês (ex.: 202703).
  int get monthKey => isLegacy ? 0 : readYear! * 100 + readMonth!;

  Book copy() => Book.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'rating': rating,
        'special': special,
        'readYear': readYear,
        'readMonth': readMonth,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: (j['id'] ?? newId()).toString(),
        title: (j['title'] ?? '').toString(),
        author: (j['author'] ?? '').toString(),
        coverUrl: j['coverUrl'] as String?,
        rating: ((j['rating'] ?? 0) as num).toDouble(),
        special: j['special'] == true,
        readYear: (j['readYear'] as num?)?.toInt(),
        readMonth: (j['readMonth'] as num?)?.toInt(),
        addedAt: DateTime.tryParse((j['addedAt'] ?? '').toString()),
      );
}

String formatRating(double r) =>
    r.toStringAsFixed(1).replaceAll('.', ',');

String monthLabel(int year, int month) => '${kMonthNames[month - 1]} de $year';
