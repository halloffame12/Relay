import 'package:relay/features/library/domain/document.dart';

/// A small, entirely fictional sample library. Every publication here is
/// invented for the prototype; none of it represents a real distributable file.
List<Document> buildSampleDocuments({DateTime? reference}) {
  final now = reference ?? DateTime.now();
  DateTime ago(int days, [int hour = 9, int minute = 30]) {
    final date = now.subtract(Duration(days: days));
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  return [
    Document(
      id: 'field-notes-quiet-places',
      title: 'Field Notes on Quiet Places',
      author: 'Mara Venn',
      source: 'Fjord Press',
      format: DocumentFormat.epub,
      sizeBytes: 2_400_000,
      addedAt: ago(2),
      pageCount: 184,
      description:
          'Four essays on attention, weather and the overlooked corners of ordinary landscapes. A quiet argument for looking longer.',
      coverDesign: CoverDesign.arch,
      coverPalette: CoverPalette.sage,
    ),
    Document(
      id: 'cartographers-apprentice',
      title: "The Cartographer's Apprentice",
      author: 'Elias Howe',
      source: 'Harbor & Vale',
      format: DocumentFormat.epub,
      sizeBytes: 3_980_000,
      addedAt: ago(3, 18, 15),
      pageCount: 312,
      description:
          'A novel about a young mapmaker who begins drawing coastlines that do not yet exist. Restrained, atmospheric and quietly strange.',
      coverDesign: CoverDesign.bands,
      coverPalette: CoverPalette.ink,
    ),
    Document(
      id: 'designing-for-attention',
      title: 'Designing for Attention',
      author: 'Dr. Lena Ortiz',
      source: 'Northfield University',
      format: DocumentFormat.pdf,
      sizeBytes: 8_450_000,
      addedAt: ago(5, 11, 5),
      pageCount: 64,
      description:
          'Lecture notes on interface rhythm, interruption and the ethics of persuasive design. Includes a twelve-page reading list.',
      coverDesign: CoverDesign.grid,
      coverPalette: CoverPalette.clay,
    ),
    Document(
      id: 'short-history-of-the-book',
      title: 'A Short History of the Book',
      author: 'Ines Aldridge',
      source: 'The Folio Room',
      format: DocumentFormat.pdf,
      sizeBytes: 13_200_000,
      addedAt: ago(7, 14, 40),
      pageCount: 142,
      description:
          'From clay tablets to paperback spines: a concise tour of how the book has been made, copied and carried.',
      coverDesign: CoverDesign.editorial,
      coverPalette: CoverPalette.ochre,
    ),
    Document(
      id: 'systems-thinking-briefly',
      title: 'Systems Thinking, Briefly',
      author: 'The Commons Research Group',
      source: 'Commons Papers',
      format: DocumentFormat.pdf,
      sizeBytes: 4_300_000,
      addedAt: ago(10, 8, 20),
      pageCount: 38,
      description:
          'A working paper on feedback loops, delays and unintended consequences, written for people who make decisions in complex organisations.',
      coverDesign: CoverDesign.frame,
      coverPalette: CoverPalette.forest,
    ),
    Document(
      id: 'letters-northern-line',
      title: 'Letters from the Northern Line',
      author: 'Tomas Krall',
      source: 'Northern Editions',
      format: DocumentFormat.epub,
      sizeBytes: 1_950_000,
      addedAt: ago(13, 19, 10),
      pageCount: 228,
      description:
          'Short letters written between two friends over a winter of late trains and early mornings. Tender without becoming sentimental.',
      coverDesign: CoverDesign.sun,
      coverPalette: CoverPalette.clay,
    ),
    Document(
      id: 'orchard-year',
      title: 'The Orchard Year',
      author: 'Ruth Ellery',
      source: 'Field & Orchard',
      format: DocumentFormat.epub,
      sizeBytes: 5_870_000,
      addedAt: ago(16, 10, 45),
      pageCount: 296,
      description:
          'A month-by-month account of restoring an old apple orchard, with notes on pruning, patience and the usefulness of a slow calendar.',
      coverDesign: CoverDesign.spine,
      coverPalette: CoverPalette.moss,
    ),
    Document(
      id: 'typography-and-the-page',
      title: 'Typography & the Page',
      author: 'Ada Merritt',
      source: 'Letterform Studies',
      format: DocumentFormat.pdf,
      sizeBytes: 19_300_000,
      addedAt: ago(21, 16, 0),
      pageCount: 206,
      description:
          'A practical study of measure, leading and margins. The sample includes annotated spreads from letterpress workbooks.',
      coverDesign: CoverDesign.editorial,
      coverPalette: CoverPalette.paper,
    ),
    Document(
      id: 'notes-on-walking',
      title: 'Notes on Walking',
      author: 'Samuel Rook',
      source: 'Wayfarer Books',
      format: DocumentFormat.epub,
      sizeBytes: 1_270_000,
      addedAt: ago(25, 7, 25),
      pageCount: 156,
      description:
          'Small observations gathered on foot: the pace of a city, the shape of a detour and what a walk can do for a stubborn thought.',
      coverDesign: CoverDesign.spine,
      coverPalette: CoverPalette.sage,
    ),
    Document(
      id: 'paper-archive',
      title: 'The Paper Archive',
      author: 'Nadia Cole',
      source: 'The Paper Archive',
      format: DocumentFormat.pdf,
      sizeBytes: 26_100_000,
      addedAt: ago(30, 12, 15),
      pageCount: 318,
      description:
          'An illustrated catalogue of envelopes, index cards and filing systems, drawn from a fictional municipal collection.',
      coverDesign: CoverDesign.arch,
      coverPalette: CoverPalette.paper,
    ),
    Document(
      id: 'small-rooms-large-windows',
      title: 'Small Rooms, Large Windows',
      author: 'June Aster',
      source: 'Quiet House',
      format: DocumentFormat.epub,
      sizeBytes: 2_940_000,
      addedAt: ago(36, 20, 5),
      pageCount: 208,
      description:
          'A collection of interiors described in one page each. Some are remembered; some are borrowed; all of them are lived in.',
      coverDesign: CoverDesign.minimal,
      coverPalette: CoverPalette.charcoal,
    ),
    Document(
      id: 'common-mosses',
      title: 'A Field Guide to Common Mosses',
      author: 'Alistair Finch',
      source: 'Moorland Field Guides',
      format: DocumentFormat.pdf,
      sizeBytes: 17_000_000,
      addedAt: ago(42, 6, 55),
      pageCount: 96,
      description:
          'An annotated field guide to twelve mosses found on walls, roofs and woodland floors. Sample plates are reconstructed in the reader.',
      coverDesign: CoverDesign.bands,
      coverPalette: CoverPalette.ochre,
    ),
  ];
}
