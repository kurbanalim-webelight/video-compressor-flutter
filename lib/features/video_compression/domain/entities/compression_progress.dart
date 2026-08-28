import 'package:equatable/equatable.dart';

class CompressionProgress extends Equatable {
  const CompressionProgress(this.fraction);

  final double fraction;

  @override
  List<Object?> get props => [fraction];
}
