/// A tiny reader for the privacy policy markdown: `# ` title, `## ` headings, `- ` bullets and
/// paragraphs. Pure so it can be tested.
enum LegalKind { heading, bullet, paragraph }

class LegalBlock {
  const LegalBlock(this.kind, this.text);
  final LegalKind kind;
  final String text;
}

class LegalDocument {
  const LegalDocument(this.title, this.blocks);
  final String title;
  final List<LegalBlock> blocks;
}

/// Parses [markdown]. `{{CONTACT}}` is replaced by [contactLine], or by [noContactLine] when the
/// build has no contact address.
LegalDocument parseLegal(
  String markdown, {
  String? contactEmail,
  String noContactLine = 'No contact address is configured in this build.',
}) {
  final contact = (contactEmail ?? '').trim();
  final text = markdown.replaceAll(
    '{{CONTACT}}',
    contact.isEmpty ? noContactLine : 'Contact: $contact',
  );
  var title = '';
  final blocks = <LegalBlock>[];
  final paragraph = <String>[];

  void flush() {
    if (paragraph.isNotEmpty) blocks.add(LegalBlock(LegalKind.paragraph, paragraph.join(' ')));
    paragraph.clear();
  }

  for (final raw in text.split('\n')) {
    final line = raw.trimRight();
    if (line.startsWith('## ')) {
      flush();
      blocks.add(LegalBlock(LegalKind.heading, line.substring(3).trim()));
    } else if (line.startsWith('# ')) {
      flush();
      title = line.substring(2).trim();
    } else if (line.startsWith('- ')) {
      flush();
      blocks.add(LegalBlock(LegalKind.bullet, line.substring(2).trim()));
    } else if (line.trim().isEmpty) {
      flush();
    } else {
      paragraph.add(line.trim());
    }
  }
  flush();
  return LegalDocument(title, blocks);
}
