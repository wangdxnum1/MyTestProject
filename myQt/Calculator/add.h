#ifndef ADD_H
#define ADD_H
#include "imath.h"

class Add : public IMath
{
public:
    Add();
    void Calculator(const QString &num1,const QString &num2,QString &result);
};

#endif // ADD_H
