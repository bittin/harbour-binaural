#include "audioengine.h"

#include <QDebug>
#include <QMap>

namespace
{
    const QMap<QString, QString> &ambienceFiles()
    {
        static const QMap<QString, QString> files = {
            { QStringLiteral("Wind"),     QStringLiteral("wind.mp3") },
            { QStringLiteral("Rain"),     QStringLiteral("rain.mp3") },
            { QStringLiteral("Stream"),   QStringLiteral("stream.mp3") },
            { QStringLiteral("Waves"),    QStringLiteral("waves.mp3") },
            { QStringLiteral("Lake"),     QStringLiteral("lake.mp3") },
            { QStringLiteral("Sailing"),  QStringLiteral("sailing.mp3") },
            { QStringLiteral("Birds"),    QStringLiteral("birds.mp3") },
            { QStringLiteral("Crickets"), QStringLiteral("crickets.mp3") },
            { QStringLiteral("Chimes"),   QStringLiteral("chimes.mp3") },
            { QStringLiteral("Fire"),     QStringLiteral("fire.mp3") }
        };

        return files;
    }
}

bool AudioEngine::isAmbiencePlaying() const
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i]
            && m_ambienceChannels[i]->isPlaying()) {
            return true;
        }
    }

    return false;
}

bool AudioEngine::isAmbiencePaused() const
{
    bool hasPausedChannel = false;

    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (!m_ambienceChannels[i])
            continue;

        if (m_ambienceChannels[i]->isPlaying())
            return false;

        if (m_ambienceChannels[i]->isPaused())
            hasPausedChannel = true;
    }

    return hasPausedChannel;
}

void AudioEngine::setAmbience(const QString &ambience)
{
    const auto it = ambienceFiles().constFind(ambience);

    if (it == ambienceFiles().constEnd())
        return;

    // Preserve the current single-selection behavior.
    stopAmbiencesImmediately();

    if (!m_ambienceChannels[0]->start(it.value())) {
        qWarning() << "AudioEngine: failed to start ambience:"
                   << ambience;

        updatePlayingState();
        return;
    }

    m_ambienceChannels[0]->setVolume(m_ambienceVolume);

    updatePlayingState();
}

void AudioEngine::pauseAmbience()
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->pause();
    }
}

void AudioEngine::resumeAmbience()
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->resume();
    }
}

void AudioEngine::stopAmbience()
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->stop();
    }
}

void AudioEngine::stopAmbiencesImmediately()
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->stopImmediately();
    }
}

void AudioEngine::setAmbienceVolume(int volume)
{
    m_ambienceVolume = qBound(0, volume, 100);

    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->setVolume(m_ambienceVolume);
    }
}
