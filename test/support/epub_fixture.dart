import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const _containerXml =
    '<?xml version="1.0"?>'
    '<container version="1.0" '
    'xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
    '<rootfiles><rootfile full-path="OEBPS/content.opf" '
    'media-type="application/oebps-package+xml"/></rootfiles></container>';

const _imageBookOpf =
    '<?xml version="1.0" encoding="utf-8"?>'
    '<package xmlns="http://www.idpf.org/2007/opf" version="2.0" '
    'unique-identifier="id">'
    '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
    '<dc:identifier id="id">urn:uuid:relay-image-test</dc:identifier>'
    '<dc:title>Bidirectional \u202E Evil  Title</dc:title>'
    '<dc:creator>  Ada  Lovelace  </dc:creator>'
    '<dc:language>en-US</dc:language>'
    '<dc:description>  A book \u202A with an image.  </dc:description>'
    '</metadata><manifest>'
    '<item id="c1" href="text/chapter1.xhtml" '
    'media-type="application/xhtml+xml"/>'
    '<item id="png" href="images/pixel.png" media-type="image/png"/>'
    '<item id="svg" href="images/evil.svg" media-type="image/svg+xml"/>'
    '<item id="gif" href="images/not-a-gif.gif" media-type="image/gif"/>'
    '<item id="ncx" href="toc.ncx" '
    'media-type="application/x-dtbncx+xml"/>'
    '</manifest><spine toc="ncx"><itemref idref="c1"/></spine></package>';

const _imageNcx =
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">'
    '<head><meta name="dtb:uid" content="urn:uuid:relay-image-test"/></head>'
    '<docTitle><text>Bidirectional Evil Title</text></docTitle>'
    '<navMap><navPoint id="nav1" playOrder="1">'
    '<navLabel><text>Pictures</text></navLabel>'
    '<content src="text/chapter1.xhtml"/></navPoint></navMap></ncx>';

const _imageChapter =
    '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Images</title>'
    '</head><body><h1>Pictures</h1><p>Before the image.</p>'
    '<p><img src="../images/pixel.png" alt="A pixel"/></p>'
    '<p>After the image.</p>'
    '<p><img src="https://example.com/tracker.png" alt="Remote"/></p>'
    '<p><img src="../images/evil.svg" alt="Evil"/></p>'
    '<p><img src="../images/not-a-gif.gif" alt="Wrong bytes"/></p>'
    '</body></html>';

const onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
    'YAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

/// Writes a minimal, valid EPUB without a navigation document. It exercises
/// chapter-relative images, a remote source, an SVG and a MIME/magic mismatch.
Future<void> writeImageEpub(File file) {
  return _writeStoredZip(file, {
    'mimetype': utf8.encode('application/epub+zip'),
    'META-INF/container.xml': utf8.encode(_containerXml),
    'OEBPS/content.opf': utf8.encode(_imageBookOpf),
    'OEBPS/toc.ncx': utf8.encode(_imageNcx),
    'OEBPS/text/chapter1.xhtml': utf8.encode(_imageChapter),
    'OEBPS/images/pixel.png': base64Decode(onePixelPng),
    'OEBPS/images/evil.svg': utf8.encode(
      '<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"/>',
    ),
    'OEBPS/images/not-a-gif.gif': base64Decode(onePixelPng),
  });
}

Future<void> _writeStoredZip(File file, Map<String, List<int>> entries) async {
  final output = BytesBuilder(copy: false);
  final central = BytesBuilder(copy: false);
  var offset = 0;
  for (final entry in entries.entries) {
    final name = utf8.encode(entry.key);
    final data = entry.value;
    final crc = _crc32(data);
    final local = BytesBuilder(copy: false)
      ..add(_le32(0x04034b50))
      ..add(_le16(20))
      ..add(_le16(0))
      ..add(_le16(0))
      ..add(_le16(0))
      ..add(_le16(0))
      ..add(_le32(crc))
      ..add(_le32(data.length))
      ..add(_le32(data.length))
      ..add(_le16(name.length))
      ..add(_le16(0))
      ..add(name)
      ..add(data);
    final localBytes = local.takeBytes();
    output.add(localBytes);

    central
      ..add(_le32(0x02014b50))
      ..add(_le16(20))
      ..add(_le16(20))
      ..add(_le16(0))
      ..add(_le16(0))
      ..add(_le16(0))
      ..add(_le16(0))
      ..add(_le32(crc))
      ..add(_le32(data.length))
      ..add(_le32(data.length))
      ..add(_le16(name.length))
      ..add(_le16(0))
      ..add(_le16(0))
      ..add(_le16(0))
      ..add(_le16(0))
      ..add(_le32(0))
      ..add(_le32(offset))
      ..add(name);
    offset += localBytes.length;
  }

  final directory = central.takeBytes();
  output
    ..add(directory)
    ..add(_le32(0x06054b50))
    ..add(_le16(0))
    ..add(_le16(0))
    ..add(_le16(entries.length))
    ..add(_le16(entries.length))
    ..add(_le32(directory.length))
    ..add(_le32(offset))
    ..add(_le16(0));
  await file.writeAsBytes(output.takeBytes(), flush: true);
}

List<int> _le16(int value) => [value & 0xFF, (value >> 8) & 0xFF];

List<int> _le32(int value) => [
  value & 0xFF,
  (value >> 8) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 24) & 0xFF,
];

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
