#ifndef CAL_H
#define CAL_H
#include <QString>
#include <QMap>
#include "imath.h"
#include <QSharedPointer>

class Cal
{
public:
    Cal();
    void AddFunction();
    void Calculator(const QString &strOperator,QString &num1,const QString &num2);
private:
    QMap<QString,QSharedPointer<IMath> > CalMap;
};

#endif // CAL_H
