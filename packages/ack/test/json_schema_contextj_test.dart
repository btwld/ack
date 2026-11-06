import 'support/idna_labels.dart';

void main() {
  // RFC 5892 Appendix A.1/A.2. Exercise both U-labels and decoded A-labels,
  // including format assertions preserved by JSON Schema export/import.
  const examples = [
    (label: 'ب\u200cا', valid: true, name: 'allows dual then right joining'),
    (
      // xn--mgba000r.example
      label: 'ا\u200cا',
      valid: false,
      name: 'rejects right-joining letter before ZWNJ',
    ),
    (
      // xn--lsa62nba726x.example
      label: 'ب\u0301\u200cا',
      valid: true,
      name: 'skips transparent joining characters',
    ),
    (
      label: 'ب\u064e\u0301\u200c\u064e\u0301ا',
      valid: true,
      name: 'skips multiple transparent characters on both sides',
    ),
    (label: 'ب\u200cب', valid: true, name: 'allows dual joining on both sides'),
    (label: 'ߊ\u200cߊ', valid: true, name: 'allows NKo joining letters'),
    (
      label: '\ua872\u200c\u1820',
      valid: true,
      name: 'allows left then dual joining outside Arabic blocks',
    ),
    (label: 'ء\u200cب', valid: false, name: 'rejects nonjoining left neighbor'),
    (
      label: 'ب\u200cء',
      valid: false,
      name: 'rejects nonjoining right neighbor',
    ),
    (
      label: 'ب\u200c\u0883',
      valid: false,
      name: 'rejects join-causing right neighbor',
    ),
    (
      label: 'ا\u064e\u200cب',
      valid: false,
      name: 'rejects right joining before transparent marks',
    ),
    (
      label: 'ب\u200c\u064eء',
      valid: false,
      name: 'rejects nonjoining after transparent marks',
    ),
    (label: '\u200cب', valid: false, name: 'rejects leading ZWNJ'),
    (label: 'ب\u200c', valid: false, name: 'rejects trailing ZWNJ'),
    (
      label: 'ب\u200c\u064e',
      valid: false,
      name: 'rejects ZWNJ with only transparent characters to the right',
    ),
    (label: 'ب\u200dا', valid: false, name: 'rejects ZWJ in joining context'),
    (
      label: 'क्\u200cष',
      valid: true,
      name: 'allows ZWNJ immediately after Virama',
    ),
    (
      label: 'क्\u200dष',
      valid: true,
      name: 'allows ZWJ immediately after Virama',
    ),
    (
      label: 'ក\u17d2\u200dក',
      valid: true,
      name: 'allows Khmer Virama before ZWJ',
    ),
    (
      label: '\u{11013}\u{11046}\u200c\u{11013}',
      valid: true,
      name: 'allows supplementary Virama before ZWNJ',
    ),
    (
      label: 'क्\u0301\u200dष',
      valid: false,
      name: 'requires Virama immediately before ZWJ',
    ),
    (
      label: 'क्\u0301\u200cष',
      valid: false,
      name: 'requires Virama immediately before nonjoining ZWNJ',
    ),
    (label: 'क्\u200d', valid: true, name: 'allows terminal ZWJ after Virama'),
    (label: 'क्\u200c', valid: true, name: 'allows terminal ZWNJ after Virama'),
  ];
  testIdnaLabels(examples);
}
