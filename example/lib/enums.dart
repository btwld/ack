/// Product status enum
enum ProductStatus {
  draft,
  published,
  archived;
  
  @override
  String toString() => name;
}