import time

class HtmlOutputer(object):
    def __init__(self):
        self.datas = []
        pass

    def collecte_data(self,newData):
        self.datas.append(newData)

    def output(self):
        with open('result.txt','a',encoding='utf-8') as f:
            timeStr = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(time.time()))
            f.write('本次抓取:')
            f.write(timeStr)
            f.write('\n')
            for data in self.datas:
                f.write(data['title'])
                f.write(' : ')
                f.write(data['url'])
                f.write(data['summary'])
                f.write('\n')
            f.close()

