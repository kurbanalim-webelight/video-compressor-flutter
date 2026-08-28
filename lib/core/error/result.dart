import 'app_failure.dart';

sealed class Result<T> {
  const Result();

  R fold<R>({required R Function(T data) onSuccess, required R Function(AppFailure failure) onFailure}) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Failed<T>(:final failure) => onFailure(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);

  final AppFailure failure;
}
