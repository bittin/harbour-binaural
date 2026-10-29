#include "audioengine.h"

#include <QMap>
#include <QDebug>
#include <QtMath>

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

// ============================================================================
// STATE
// ============================================================================

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
    bool foundPausedChannel = false;

    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        AmbienceChannel *channel = m_ambienceChannels[i];

        if (!channel)
            continue;

        if (channel->isPlaying())
            return false;

        if (channel->isPaused())
            foundPausedChannel = true;
    }

    return foundPausedChannel;
}

// ============================================================================
// PLAYBACK
// ============================================================================

void AudioEngine::setAmbience(const QString &ambience)
{
    const auto it = ambienceFiles().constFind(ambience);

    if (it == ambienceFiles().constEnd()) {
        qWarning() << "AudioEngine: unknown ambience:" << ambience;
        return;
    }

    // Do not start the same sound in multiple channels.
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        AmbienceChannel *channel = m_ambienceChannels[i];

        if (channel
                && channel->fileName() == it.value()
                && !channel->isStopping())
            return;
    }

    // Find the first free channel.
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        AmbienceChannel *channel = m_ambienceChannels[i];

        if (!channel || !channel->fileName().isEmpty())
            continue;

        channel->setVolume(m_ambienceVolume);

        if (!channel->start(it.value())) {
            qWarning()
                << "AudioEngine: failed to start ambience:"
                << ambience;
        }

        updatePlayingState();
        return;
    }

    // All three channels are occupied. Reject the fourth sound.
    qWarning()
        << "AudioEngine: maximum of"
        << MaxAmbienceChannels
        << "simultaneous ambiences reached";
}

void AudioEngine::pauseAmbience()
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->pause();
    }

    updatePlayingState();
}

void AudioEngine::resumeAmbience()
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->resume();
    }

    updatePlayingState();
}

void AudioEngine::stopAmbience()
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->stop();
    }

    updatePlayingState();
}

void AudioEngine::stopAmbienceByName(const QString &ambience)
{
    const auto it = ambienceFiles().constFind(ambience);

    if (it == ambienceFiles().constEnd())
        return;

    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        AmbienceChannel *channel = m_ambienceChannels[i];

        if (channel && channel->fileName() == it.value()) {
            // Stop only the requested sound with a short fade-out,
            // consistent with the binaural and colored-noise channels.
            // AmbienceChannel emits finished() when the fade completes.
            channel->stop();
            break;
        }
    }

    updatePlayingState();
}

void AudioEngine::stopAmbiencesImmediately()
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->stopImmediately();
    }

    updatePlayingState();
}

// ============================================================================
// VOLUME
// ============================================================================

void AudioEngine::setAmbienceVolume(int volume)
{
    m_ambienceVolume = qBound(0, volume, 100);

    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        if (m_ambienceChannels[i])
            m_ambienceChannels[i]->setVolume(m_ambienceVolume);
    }
}
