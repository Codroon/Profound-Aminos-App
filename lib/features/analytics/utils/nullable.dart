class Nullable<T> {
  final T value;
  const Nullable(this.value);
}
 
extension NullableExtension<T> on T {
  Nullable<T> get nullable => Nullable(this);
}