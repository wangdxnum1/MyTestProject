from SpiderManager import *

def main():
    rootUrl = "http://baike.baidu.com/view/21087.htm"
    print("开始爬虫 rootUrl = ",rootUrl)

    s = SpiderManager()
    s.craw(rootUrl)

if __name__ == "__main__":
    main()