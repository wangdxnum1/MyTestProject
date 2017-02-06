#include "add.h"

Add::Add():IMath()
{
}
void Add::Calculator(const QString &num1,const QString &num2,QString &result)
{
    bool bOk = false;
    int inum1 = num1.toInt(&bOk);
    int inum2 = num2.toInt(&bOk);

    int iResult = inum1 + inum2;

    result = QString::number(iResult);
}
