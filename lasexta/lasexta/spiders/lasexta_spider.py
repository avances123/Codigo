from scrapy.spider import BaseSpider

class LasextaSpider(BaseSpider):
    domain_name = "lasextadeportes.com"
    start_urls = [
        "http://www.lasextadeportes.com/futbol/equipo/detalle/3/barcelona/",
    ]

    def parse(self, response):
        filename = response.url.split("/")[-2]
        open(filename, 'wb').write(response.body)

SPIDER = LasextaSpider()

