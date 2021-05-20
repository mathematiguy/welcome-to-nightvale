import os
import scrapy


class TranscriptsSpider(scrapy.Spider):
    name = 'transcripts'
    corpus_dir = 'corpus'
    allowed_domains = ['nightvalepresents.com']
    start_urls = ['http://nightvalepresents.com/welcome-to-night-vale-transcripts/2021/5/15/188-listener-questions']

    def parse(self, response):

        # Get the transcript title
        title = response.xpath('//header/h1/a/text()').extract()[0]

        # Get the transcript
        transcript = '\n\n'.join(
            response.xpath('//div[contains(@class, "sqs-block-content")]/p/text()').extract()
        )

        # Write file to disk
        corpus_file = os.path.join(self.corpus_dir, response.url.rsplit('/', 1)[-1]) + '.txt'
        with open(corpus_file, 'w') as f:
            f.write(title + '\n\n' + transcript)

        # Get the url to the next page
        next_page = response.xpath('//a[@id="nextLink"]/@href').extract()

        if len(next_page) > 0:
            next_url = response.urljoin(next_page[0])
            yield scrapy.Request(next_url, callback = self.parse)
