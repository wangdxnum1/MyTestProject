from UrlManager import *
from HtmlDownloader import *
from HtmlParser import *
from HtmlOutputer import *

class SpiderManager(object):
    def __init__(self):
        self.urlManager = UrlManager()
        self.htmlDownloader = HtmlDownloader()
        self.htmlParser = HtmlParser()
        self.outputer = HtmlOutputer()

    def craw(self, root_url):
        if root_url is None:
            return

        self.urlManager.add_new_url(root_url)
        count = 0
        while self.urlManager.has_new_url():
            try:
                url = self.urlManager.get_new_url()
                # 下载html
                html = self.htmlDownloader.download(url)

                # 解析html
                newUrls,newDatas = self.htmlParser.parser(url,html)

                # print(newUrls)

                self.outputer.collecte_data(newDatas)
                self.urlManager.add_new_urls(newUrls)
                count += 1
                if count == 10:
                    break

            except e:
                print(e)
        self.outputer.output()
        print('爬虫结束')
