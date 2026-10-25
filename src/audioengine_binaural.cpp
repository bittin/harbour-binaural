#include "audioengine.h"
#include "binauralgenerator.h"

#include <QAudioFormat>
#include <QMap>
#include <QtMath>

namespace
{
    double frequencyForBand(const QString &band)
    {
        static const QMap<QString, double> bands = {
            { QStringLiteral("Delta"),          2.0 },
            { QStringLiteral("Delta/Theta"),    4.0 },
            { QStringLiteral("Theta"),          6.0 },
            { QStringLiteral("Alpha"),         10.0 },
            { QStringLiteral("Beta"),          20.0 },
            { QStringLiteral("Gamma"),         40.0 }
        };

        return bands.value(band, -1.0);
    }

    const int BinauralFadeOutDuration = 200;

}

// ============================================================================
// STATE
// ============================================================================

bool AudioEngine::isBinauralPlaying() const
{
    return m_binauralChannel->isPlaying();
}

bool AudioEngine::isBinauralPaused() const
{
    return m_binauralChannel->isPaused();
}

// ============================================================================
// RESUME / FREQUENCY / VOLUME
// ============================================================================

void AudioEngine::resumeBinaural()
{
    m_binauralChannel->resume();
}

void AudioEngine::setFrequencyBand(const QString &band)
{
    const double frequency = frequencyForBand(band);
    if (frequency < 0.0)
        return;

    m_beatFrequency = frequency;

    if (m_binauralGenerator)
        m_binauralGenerator->setBeatFrequency(m_beatFrequency);
}

void AudioEngine::setBinauralVolume(int volume)
{
    m_binauralVolume =
        qBound(0, volume, 100);

    m_binauralChannel->setVolume(
        m_binauralVolume / 100.0);
}

// ============================================================================
// BINAURAL
// ============================================================================

void AudioEngine::start()
{
    if (m_binauralChannel->isRunning())
    {
        /*
         * Starting while a fade-out is running cancels
         * the fade-out and restores the requested volume.
         */
        if (m_binauralChannel->isFadingOut())
        {
            m_binauralChannel->cancelFadeOut();

            m_binauralChannel->setVolume(
                m_binauralVolume / 100.0);
        }

        return;
    }

    auto *generator =
        new BinauralGenerator(m_binauralChannel);

    const bool started = m_binauralChannel->start(
        generator,
        [this, generator](const QAudioFormat &format)
        {
            generator->setBeatFrequency(m_beatFrequency);
            generator->setSampleRate(format.sampleRate());
            generator->start();
        });

    if (!started)
    {
        delete generator;
        return;
    }

    m_binauralGenerator = generator;

    updatePlayingState();
}

void AudioEngine::pauseBinaural()
{
    m_binauralChannel->pause();

    updatePlayingState();
}

void AudioEngine::stop()
{
    if (!m_binauralChannel->isRunning())
        return;

    m_binauralChannel->beginFadeOut(
        BinauralFadeOutDuration);
}
