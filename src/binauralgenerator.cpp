#include "binauralgenerator.h"

#include <QtMath>
#include <cstring>

namespace
{
    const int DefaultSampleRate = 48000;

    const double CarrierFrequency = 200.0;

    // MASTER VOLUME Binaural
    const double BinauralAmplitude = 13000.0;
}

// ============================================================================
// BINAURAL GENERATOR
// ============================================================================

BinauralGenerator::BinauralGenerator(QObject *parent)
    : QIODevice(parent),
      m_sampleRate(DefaultSampleRate),
      m_leftPhase(0.0),
      m_rightPhase(0.0),
      m_beatFrequency(10.0)
{
}

void BinauralGenerator::start()
{
    open(QIODevice::ReadOnly);
}

void BinauralGenerator::stop()
{
    close();
    m_leftPhase = 0.0;
    m_rightPhase = 0.0;
}

void BinauralGenerator::setBeatFrequency(double frequency)
{
    m_beatFrequency = qMax(0.0, frequency);
}

void BinauralGenerator::setSampleRate(int sampleRate)
{
    if (sampleRate > 0)
        m_sampleRate = sampleRate;
}

qint64 BinauralGenerator::readData(char *data, qint64 maxlen)
{
    const qint64 bytesPerFrame = 4; // stereo, 16 bit
    const qint64 frameCount = maxlen / bytesPerFrame;

    qint16 *samples =
        reinterpret_cast<qint16 *>(data);

    const double leftFrequency = CarrierFrequency;
    const double rightFrequency =
        CarrierFrequency + m_beatFrequency;

    for (qint64 frame = 0; frame < frameCount; ++frame)
    {
        samples[frame * 2] =
            static_cast<qint16>(
                qSin(m_leftPhase * 2.0 * M_PI)
                * BinauralAmplitude);

        samples[frame * 2 + 1] =
            static_cast<qint16>(
                qSin(m_rightPhase * 2.0 * M_PI)
                * BinauralAmplitude);

        m_leftPhase += leftFrequency / m_sampleRate;
        m_rightPhase += rightFrequency / m_sampleRate;

        if (m_leftPhase >= 1.0)
            m_leftPhase -= 1.0;

        if (m_rightPhase >= 1.0)
            m_rightPhase -= 1.0;
    }

    const qint64 usedBytes =
        frameCount * bytesPerFrame;

    if (usedBytes < maxlen)
    {
        std::memset(
            data + usedBytes,
            0,
            static_cast<size_t>(maxlen - usedBytes));
    }

    return maxlen;
}

qint64 BinauralGenerator::writeData(const char *, qint64)
{
    return 0;
}
