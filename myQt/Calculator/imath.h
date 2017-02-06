#ifndef IMATH_H
#define IMATH_H

#include <QString>

class IMath
{
public:
    IMath()
    {

    }
    virtual ~IMath()
    {

    }
    virtual void Calculator(const QString &num1,const QString &num2,QString &result) = 0;
};

#endif // IMATH_H
