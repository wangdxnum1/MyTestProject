#-------------------------------------------------
#
# Project created by QtCreator 2014-09-26T22:15:07
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = Calculator
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp \
    cal.cpp \
    add.cpp

HEADERS  += mainwindow.h \
    cal.h \
    imath.h \
    add.h

FORMS    += mainwindow.ui

RC_FILE  += icon.rc
