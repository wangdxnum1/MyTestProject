#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QSignalMapper>
#include <QtGlobal>
#include "cal.h"

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();
private:
   void SetDetailForUi();
   void Initialize();
private slots:
   void on_number_clicked(const QString &number);
   void on_operator_clicked(const QString& strOperator);
private:
    Ui::MainWindow *ui;
    QSignalMapper *numberMap;
    QSignalMapper *operatorMap;
//About logic class member
private:
    QString m_strNumber1;
    QString m_strNumber2;

    QString m_strOperator;

    bool m_bIsPiont1;
    bool m_bOperate;
private:
    Cal cal;
};

#endif // MAINWINDOW_H
