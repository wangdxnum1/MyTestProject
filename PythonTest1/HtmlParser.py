from bs4 import *
import re
import urllib.parse

class HtmlParser(object):
    def __init__(self):
        pass

    def get_new_urls(self,bs,url):
        if bs is None or url is None:
            return None

        newUrls = set()
        links = bs.find_all('a',href=re.compile(r"/view/\d+.htm"))
        for link in links:
            newUrl = link['href']
            newFullUrl = urllib.parse.urljoin(url,newUrl)
            newUrls.add(newFullUrl)

        return newUrls

    def get_new_datas(self,bs,url):
        if(bs is None or url is None):
            return None;

        resData = {}
        titleNode = bs.find('dd',class_='lemmaWgt-lemmaTitle-title').find('h1')
        resData['url'] = url
        resData['title'] = titleNode.get_text()

        summaryNode = bs.find('div', class_="lemma-summary")
        resData['summary'] = summaryNode.get_text()
        return resData

    def parser(self,url,html):
        if url is None or html is None:
            return None

        bs = BeautifulSoup(html,'html.parser',from_encoding='utf-8')
        newUrls = self.get_new_urls(bs,url)
        newDatas = self.get_new_datas(bs,url)
        return newUrls,newDatas
