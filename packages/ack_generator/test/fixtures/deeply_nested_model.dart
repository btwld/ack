import 'package:ack/ack.dart';

part 'deeply_nested_model.g.dart';

/// Level 1 - Top level model
@Schema(description: 'Top level model for deep nesting test')
class Level1 {
  @IsNotEmpty()
  final String name;
  
  final Level2 level2;
  
  Level1({
    required this.name,
    required this.level2,
  });
}

/// Level 2 - Second level model
@Schema(description: 'Second level nested model')
class Level2 {
  @IsEmail()
  final String email;
  
  final Level3 level3;
  
  @Nullable()
  final String? description;
  
  Level2({
    required this.email,
    required this.level3,
    this.description,
  });
}

/// Level 3 - Third level model
@Schema(description: 'Third level deeply nested model')
class Level3 {
  @MinLength(5)
  final String value;
  
  final int count;
  
  final Level4 level4;
  
  Level3({
    required this.value,
    required this.count,
    required this.level4,
  });
}

/// Level 4 - Fourth level model (deepest)
@Schema(description: 'Fourth level deepest nested model')
class Level4 {
  final bool isActive;
  
  final DateTime timestamp;
  
  final List<String> tags;
  
  @Required()
  final String? metadata;
  
  Level4({
    required this.isActive,
    required this.timestamp,
    required this.tags,
    this.metadata,
  });
}
