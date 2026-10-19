class GovernmentScheme {
  final String id;
  final String title;
  final String description;
  final String eligibility;
  final String benefits;
  final String deadline;
  final String sourceUrl;
  final String category; // e.g., 'Subsidy', 'Insurance', 'Loan'

  GovernmentScheme({
    required this.id,
    required this.title,
    required this.description,
    required this.eligibility,
    required this.benefits,
    required this.deadline,
    required this.sourceUrl,
    required this.category,
  });

  factory GovernmentScheme.fromJson(Map<String, dynamic> json) {
    return GovernmentScheme(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      eligibility: json['eligibility'] as String,
      benefits: json['benefits'] as String,
      deadline: json['deadline'] as String,
      sourceUrl: json['sourceUrl'] as String,
      category: json['category'] as String,
    );
  }
}
