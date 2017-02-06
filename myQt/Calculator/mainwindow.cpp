#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QDebug>
#include <QApplication>

const QString kstrPoint(".");
const QString kstrZero("0");
const QString kstrEqual("=");

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    SetDetailForUi();
    Initialize();
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::SetDetailForUi()
{
    setFixedSize(this->width(),this->height());
}

void MainWindow::Initialize()
{
    //initialize logic class member
    m_strNumber1 = "0";
    m_strNumber2 = "0";
    m_bIsPiont1 =false;
    m_bOperate = false;
    //Connect signal and slot with signalmap 0 - 9 and .
    numberMap = new QSignalMapper(this);
    connect(ui->pushButton_0,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_0,ui->pushButton_0->text());

    connect(ui->pushButton_1,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_1,ui->pushButton_1->text());

    connect(ui->pushButton_2,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_2,ui->pushButton_2->text());

    connect(ui->pushButton_3,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_3,ui->pushButton_3->text());

    connect(ui->pushButton_4,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_4,ui->pushButton_4->text());

    connect(ui->pushButton_5,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_5,ui->pushButton_5->text());

    connect(ui->pushButton_6,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_6,ui->pushButton_6->text());

    connect(ui->pushButton_7,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_7,ui->pushButton_7->text());

    connect(ui->pushButton_8,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_8,ui->pushButton_8->text());

    connect(ui->pushButton_9,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_9,ui->pushButton_9->text());

    connect(ui->pushButton_Point,SIGNAL(clicked()),numberMap,SLOT(map()));
    numberMap->setMapping(ui->pushButton_Point,ui->pushButton_Point->text());

    connect(numberMap,SIGNAL(mapped(const QString&)),this,SLOT(on_number_clicked(const QString&)));

    //connect operator + - * / =
    operatorMap = new QSignalMapper(this);
    connect(ui->pushButton_Add,SIGNAL(clicked()),operatorMap,SLOT(map()));
    operatorMap->setMapping(ui->pushButton_Add,ui->pushButton_Add->text());

    connect(ui->pushButton_Sub,SIGNAL(clicked()),operatorMap,SLOT(map()));
    operatorMap->setMapping(ui->pushButton_Sub,ui->pushButton_Sub->text());

    connect(ui->pushButton_Mul,SIGNAL(clicked()),operatorMap,SLOT(map()));
    operatorMap->setMapping(ui->pushButton_Mul,ui->pushButton_Mul->text());

    connect(ui->pushButton_Dev,SIGNAL(clicked()),operatorMap,SLOT(map()));
    operatorMap->setMapping(ui->pushButton_Dev,ui->pushButton_Dev->text());

    connect(ui->pushButton_Equal,SIGNAL(clicked()),operatorMap,SLOT(map()));
    operatorMap->setMapping(ui->pushButton_Equal,ui->pushButton_Equal->text());

    connect(operatorMap,SIGNAL(mapped(const QString&)),this,SLOT(on_operator_clicked(const QString&)));

    //initalize operator
    cal.AddFunction();
}

void MainWindow::on_number_clicked(const QString &number)
{
    qDebug()<<number;

    if(m_bOperate)
    {
        ui->lineEdit->clear();
        m_bOperate = false;
    }

    if(m_bIsPiont1 && kstrPoint == number)
    {
        QApplication::beep();
        return;
    }
    QString lineInfo = ui->lineEdit->text();
    if(lineInfo == kstrZero && number != kstrPoint)
    {
        ui->lineEdit->setText(number);
        //m_strNumber1 = number;
        return;
    }
    if(number == kstrPoint)
    {
        m_bIsPiont1 = true;
        //ui->pushButton_Point->setEnabled(false);
    }
    lineInfo.append(number);
    ui->lineEdit->setText(lineInfo);
    //m_strNumber1 = lineInfo;
    //qDebug()<<"This is a point";

}

void MainWindow::on_operator_clicked(const QString& strOperator)
{
    //qDebug()<<strOperator;
    //m_strOperator.clear();
    if(strOperator != kstrEqual)
    {
        m_strOperator = strOperator;
        qDebug()<<"m_strOperator = "<<strOperator;

//        if(m_strOperator.isEmpty() /*&& m_strNumber1 != ui->lineEdit->text()*/)
//        {

//        }
        m_strNumber1 =  ui->lineEdit->text();
        m_bOperate = true;
    }
    else
    {
        m_strNumber2 =  ui->lineEdit->text();
        cal.Calculator(m_strOperator,m_strNumber1,m_strNumber2);
        ui->lineEdit->setText(m_strNumber1);
    }
}




















