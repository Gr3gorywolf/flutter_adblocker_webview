class ResourceRule {
  ResourceRule({
    required this.url,
    this.isException = false,
    this.domains,
    this.resourceTypes,
    this.isImportant = false,
    this.isThirdParty = false,
  });
  final String url;
  final bool isException;
  final List<String>? domains;
  final List<String>? resourceTypes;
  final bool isImportant;
  final bool isThirdParty;
}
