// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http_toolkit/http_toolkit.dart';

class _Todo {
  const _Todo({
    required this.userId,
    required this.id,
    required this.title,
    this.completed = false,
  });

  factory _Todo.fromJson(Map<String, dynamic> json) {
    if (json case {
      'id': final int id,
      'userId': final int userId,
      'title': final String title,
      'completed': final bool completed,
    }) {
      return _Todo(
        id: id,
        userId: userId,
        title: title,
        completed: completed,
      );
    }

    throw const FormatException('Invalid JSON');
  }

  final int id;
  final int userId;
  final String title;
  final bool completed;

  @override
  String toString() =>
      'Todo( id: $id, userId: $userId, title: $title, completed: $completed)';
}

void main() async {
  final client = Client(
    middlewares: [
      const BaseUrlMiddleware('https://jsonplaceholder.typicode.com'),
    ],
  );

  // The usual way
  try {
    final response = await client.get(
      Uri.parse('/todos/1'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final todo = _Todo.fromJson(json);

      print(todo);
    } else {
      throw const HttpException('Something Went Wrong');
    }
  } on Exception catch (e) {
    print('Error: $e');
  }

  // Using http_toolkit
  try {
    final todo = await client.getDecoded(
      Uri.parse('/todos/1'),
      responseValidator: ResponseValidator.success,
      mapper: _Todo.fromJson,
    );

    print(todo);
  } on Exception catch (e) {
    print('Error: $e');
  }

  client.close();
}
