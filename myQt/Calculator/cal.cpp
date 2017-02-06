#include "cal.h"
#include "add.h"
#include <QDebug>

const QString kAddOperator("+");
const QString kSubOperator("-");
const QString kMulOperator("*");
const QString kDevOperator("/");

Cal::Cal()
{
}
void Cal::Calculator(const QString &strOperator,QString &num1,const QString &num2)
{
    qDebug()<<"Cal::Calculator"<<num1<<"  "<<num2;
    QMap<QString,QSharedPointer<IMath> >::iterator it = CalMap.find(strOperator);
    if(it != CalMap.end())
    {
        QString result;
        it.value()->Calculator(num1,num2,result);
        num1 = result;
        qDebug()<<"Cal::Calculator result = "<<result;
    }
    else
    {
        qDebug()<<"Cal::Calculator can not find the operator";
    }
}

void Cal::AddFunction()
{
    QSharedPointer<IMath> spIadd(new Add);
    CalMap.insert(kAddOperator,spIadd);
}
