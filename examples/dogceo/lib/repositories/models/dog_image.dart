final class DogImage {
  const DogImage(this.imageURL);

  final String imageURL;

  factory DogImage.fromString(String imageURL) => DogImage(imageURL);

  @override
  int get hashCode => imageURL.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return (other is DogImage) && other.imageURL == imageURL;
  }

  @override
  String toString() => "DogImage(imageURL: $imageURL)";
}
