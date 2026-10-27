#ifndef BINAURALGENERATOR_H
#define BINAURALGENERATOR_H

#include <QIODevice>

class BinauralGenerator : public QIODevice
{
public:
    explicit BinauralGenerator(QObject *parent = nullptr);

    void start();

    void setBeatFrequency(double frequency);
    void setSampleRate(int sampleRate);

protected:
    qint64 readData(char *data, qint64 maxlen) override;
    qint64 writeData(const char *, qint64) override;

private:
    double m_sampleRate;
    double m_leftPhase;
    double m_rightPhase;
    double m_beatFrequency;
};

#endif
