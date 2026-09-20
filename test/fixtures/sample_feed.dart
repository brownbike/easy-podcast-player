const String sampleFeedXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
  <channel>
    <title>Sample Kids Podcast</title>
    <link>https://example.com</link>
    <description>Sample</description>
    <item>
      <title>Episode 1</title>
      <description>Intro</description>
      <pubDate>Tue, 10 Feb 2026 15:04:05 -0500</pubDate>
      <guid>ep-1</guid>
      <enclosure url="https://example.com/ep1.mp3" type="audio/mpeg" length="12345"/>
      <itunes:duration>1:23:45</itunes:duration>
      <itunes:image href="https://example.com/ep1.jpg"/>
    </item>
    <item>
      <title>Episode 2</title>
      <pubDate>Wed, 11 Feb 2026 10:00:00 +0000</pubDate>
      <guid>ep-2</guid>
      <enclosure url="https://example.com/ep2.mp3" type="audio/mpeg" length="10000"/>
      <itunes:duration>3600</itunes:duration>
    </item>
    <item>
      <title>Episode without enclosure should be skipped</title>
      <guid>ep-3</guid>
    </item>
  </channel>
</rss>
''';

String buildFeed({required int itemCount}) {
  final items = StringBuffer();
  for (var i = 1; i <= itemCount; i++) {
    items.writeln(
      '<item>'
      '<title>Episode $i</title>'
      '<guid>ep-$i</guid>'
      '<enclosure url="https://example.com/ep$i.mp3" type="audio/mpeg" length="1"/>'
      '</item>',
    );
  }
  return '<?xml version="1.0" encoding="UTF-8"?>'
      '<rss version="2.0">'
      '<channel>'
      '<title>Feed</title>'
      '$items'
      '</channel>'
      '</rss>';
}
