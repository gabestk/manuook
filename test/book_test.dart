import 'package:flutter_test/flutter_test.dart';
import 'package:manuook/models/book.dart';

void main() {
  test('livro vai e volta do JSON', () {
    final b = Book(id: '1', title: 'Dom Casmurro', rating: 4.5, readYear: 2027, readMonth: 3);
    final c = Book.fromJson(b.toJson());
    expect(c.title, 'Dom Casmurro');
    expect(c.rating, 4.5);
    expect(c.isLegacy, false);
    expect(c.monthKey, 202703);
  });

  test('5 estrelas especial só vale com nota 5', () {
    final b = Book(id: '2', title: 'X', rating: 4.5, special: true);
    expect(b.isSpecial, false);
    b.rating = 5;
    expect(b.isSpecial, true);
  });
}
