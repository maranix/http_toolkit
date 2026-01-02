final class Breed {
  const Breed(this.slug);

  final String slug;

  String get name => "${slug[0].toUpperCase()}${slug.substring(1)}";

  factory Breed.fromString(String name) => Breed(name);

  @override
  int get hashCode => slug.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return (other is Breed) && other.slug == slug;
  }

  @override
  String toString() => "Breed(slug: $slug)";
}

final class SubBreed {
  const SubBreed({required this.breed, required this.slug});

  final Breed breed;
  final String slug;

  String get name => "${slug[0].toUpperCase()}${slug.substring(1)}";

  @override
  int get hashCode => breed.hashCode ^ slug.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return (other is SubBreed) && other.slug == slug && other.breed == breed;
  }

  @override
  String toString() => "SubBreed(slug: $slug, breed: ${breed.slug})";
}
