import 'package:dogceo/types.dart';

sealed class DogServiceResponse<T> {
  const DogServiceResponse({required this.message, required this.status});

  final T message;
  final String status;

  bool get isSuccess => status == "success";
}

final class AllBreedsResponse extends DogServiceResponse<Map<String, List>> {
  const AllBreedsResponse({required super.message, required super.status});

  factory AllBreedsResponse.fromJson(JSON json) {
    if (json case {
      "message": final Map message,
      "status": final String status,
    }) {
      return AllBreedsResponse(
        message: message.cast<String, List>(),
        status: status,
      );
    }

    throw FormatException(
      "AllBreedsResponse.fromJSON: Recieved malformed JSON value",
      json,
    );
  }
}

final class ImageResponse extends DogServiceResponse<String> {
  const ImageResponse({required super.message, required super.status});

  factory ImageResponse.fromJson(JSON json) {
    if (json case {
      "message": final String message,
      "status": final String status,
    }) {
      return ImageResponse(message: message, status: status);
    }

    throw FormatException(
      "ImageResponse.fromJSON: Recieved malformed JSON value",
      json,
    );
  }
}

final class ImageListResponse extends DogServiceResponse<List<String>> {
  const ImageListResponse({required super.message, required super.status});

  factory ImageListResponse.fromJson(JSON json) {
    if (json case {
      "message": final List message,
      "status": final String status,
    }) {
      return ImageListResponse(message: message.cast<String>(), status: status);
    }

    throw FormatException(
      "ImageListResponse.fromJSON: Recieved malformed JSON value",
      json,
    );
  }
}
