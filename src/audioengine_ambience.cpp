#include "audioengine.h"

#include <QDebug>
#include <QMap>
#include <QMediaContent>
#include <QUrl>
#include <QtMath>

namespace
{
    const int AmbienceFadeInDuration = 200;
    const int AmbienceFadeOutDuration = 200;
    const int FadeInterval = 15;

    const QString AmbienceBasePath =
        QStringLiteral(
            "file:///usr/share/harbour-binaural/sounds/");

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
            { QStringLiteral("Fire"),     QStringLiteral("fire.mp3") },
        };

        return files;
    }
}


// ============================================================================
// STATE
// ============================================================================

bool AudioEngine::isAmbiencePlaying() const
{
    return m_activeAmbiencePlayer &&
           m_activeAmbiencePlayer->state()
               == QMediaPlayer::PlayingState;
}

bool AudioEngine::isAmbiencePaused() const
{
    return m_activeAmbiencePlayer &&
           m_activeAmbiencePlayer->state()
               == QMediaPlayer::PausedState;
}


// ============================================================================
// RESUME
// ============================================================================

void AudioEngine::resumeAmbience()
{
    if (isAmbiencePaused())
        m_activeAmbiencePlayer->play();
}


// ============================================================================
// VOLUME
// ============================================================================

void AudioEngine::setAmbienceVolume(int volume)
{
    m_ambienceVolume =
        qBound(0, volume, 100);

    m_ambienceVolumeTimer->start();
}

int AudioEngine::ambienceTargetVolume() const
{
    return qRound(
        // MASTER VOLUME Adjuster Ambience Noise
        m_ambienceVolume * 0.6);
}

void AudioEngine::applyPendingAmbienceVolume()
{
    if (m_activeAmbiencePlayer &&
        !m_ambienceFadeInTimer->isActive() &&
        !m_ambienceCrossfadeTimer->isActive() &&
        !m_ambienceFadeOutTimer->isActive())
    {
        m_activeAmbiencePlayer->setVolume(
            ambienceTargetVolume());
    }
}


// ============================================================================
// AMBIENCE PLAYER CONNECTIONS
// ============================================================================

void AudioEngine::connectAmbiencePlayer(
    QMediaPlayer *player)
{
    connect(player,
            &QMediaPlayer::positionChanged,
            this,
            [this, player](qint64)
            {
                checkAmbienceCrossfade(player);
            });

    connect(player,
            &QMediaPlayer::mediaStatusChanged,
            this,
            [this, player](QMediaPlayer::MediaStatus status)
            {
                if (status == QMediaPlayer::EndOfMedia)
                {
                    handleAmbienceEndOfMedia(player);
                }
                else if (status ==
                         QMediaPlayer::InvalidMedia)
                {
                    qWarning()
                        << "AudioEngine: invalid ambience:"
                        << player->media()
                               .canonicalUrl()
                               .toString();
                }
            });

    connect(
        player,
        static_cast<void (QMediaPlayer::*)(
            QMediaPlayer::Error)>(&QMediaPlayer::error),
        this,
        [player](QMediaPlayer::Error error)
        {
            qWarning()
                << "AudioEngine: ambience error:"
                << error
                << player->errorString();
        });

    connect(player,
            &QMediaPlayer::stateChanged,
            this,
            [this, player](QMediaPlayer::State state)
            {
                Q_UNUSED(state)

                updatePlayingState();

                if (state !=
                        QMediaPlayer::PlayingState ||
                    player !=
                        m_activeAmbiencePlayer ||
                    m_ambienceCrossfadeTimer->isActive() ||
                    m_ambienceFadeOutTimer->isActive())
                {
                    return;
                }

                if (!m_ambienceFadeInTimer->isActive())
                {
                    player->setVolume(
                        ambienceTargetVolume());
                }
            });
}


// ============================================================================
// AMBIENCE PLAYBACK
// ============================================================================

void AudioEngine::setAmbience(
    const QString &ambience)
{
    const QMap<QString, QString> &files = ambienceFiles();

    const QMap<QString, QString>::const_iterator it =
        files.constFind(ambience);

    if (it == files.constEnd())
        return;

    const QUrl mediaUrl = QUrl(AmbienceBasePath + it.value());

    stopAmbienceImmediately();

    m_activeAmbiencePlayer =
        m_ambiencePlayerA;

    m_activeAmbiencePlayer->setMedia(mediaUrl);
    m_activeAmbiencePlayer->setVolume(0);

    m_ambienceFadeInPosition = 0;

    m_activeAmbiencePlayer->play();

    m_ambienceFadeInTimer->start();
}

void AudioEngine::pauseAmbience()
{
    if (!m_activeAmbiencePlayer ||
        m_activeAmbiencePlayer->state()
            != QMediaPlayer::PlayingState)
        return;

    m_ambienceFadeInTimer->stop();
    m_ambienceCrossfadeTimer->stop();
    m_ambienceFadeOutTimer->stop();

    m_activeAmbiencePlayer->pause();

    if (m_fadingAmbiencePlayer)
        m_fadingAmbiencePlayer->pause();

    updatePlayingState();
}

void AudioEngine::stopAmbience()
{
    if (!m_activeAmbiencePlayer)
    {
        stopAmbienceImmediately();
        return;
    }

    if (m_ambienceFadeOutTimer->isActive())
        return;

    m_ambienceFadeInTimer->stop();
    m_ambienceCrossfadeTimer->stop();

    m_ambienceFadeOutActiveVolume =
        m_activeAmbiencePlayer->volume();

    m_ambienceFadeOutFadingVolume =
        m_fadingAmbiencePlayer
            ? m_fadingAmbiencePlayer->volume()
            : 0;

    m_ambienceFadeOutElapsed.start();
    m_ambienceFadeOutTimer->start();
}

void AudioEngine::stopAmbienceImmediately()
{
    m_ambienceFadeInTimer->stop();
    m_ambienceCrossfadeTimer->stop();
    m_ambienceFadeOutTimer->stop();
    m_ambienceVolumeTimer->stop();

    m_ambiencePlayerA->stop();
    m_ambiencePlayerB->stop();

    m_ambiencePlayerA->setVolume(0);
    m_ambiencePlayerB->setVolume(0);

    m_activeAmbiencePlayer = nullptr;
    m_fadingAmbiencePlayer = nullptr;

    m_ambienceFadeInPosition = 0;
    m_ambienceCrossfadePosition = 0;

    m_ambienceFadeOutActiveVolume = 0;
    m_ambienceFadeOutFadingVolume = 0;

    updatePlayingState();
}


// ============================================================================
// FADE IN / FADE OUT
// ============================================================================

void AudioEngine::updateAmbienceFadeIn()
{
    if (!m_activeAmbiencePlayer)
    {
        m_ambienceFadeInTimer->stop();
        return;
    }

    m_ambienceFadeInPosition += FadeInterval;

    const double progress =
        AmbienceFadeInDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(
                      m_ambienceFadeInPosition)
                      / AmbienceFadeInDuration)
            : 1.0;

    const int maximumVolume =
        ambienceTargetVolume();

    m_activeAmbiencePlayer->setVolume(
        qRound(maximumVolume * progress));

    if (progress >= 1.0)
    {
        m_activeAmbiencePlayer->setVolume(
            maximumVolume);

        m_ambienceFadeInTimer->stop();
        m_ambienceFadeInPosition = 0;
    }
}

void AudioEngine::updateAmbienceFadeOut()
{
    if (!m_activeAmbiencePlayer)
    {
        m_ambienceFadeOutTimer->stop();
        return;
    }

    const double progress =
        AmbienceFadeOutDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(
                      m_ambienceFadeOutElapsed.elapsed())
                      / AmbienceFadeOutDuration)
            : 1.0;

    m_activeAmbiencePlayer->setVolume(
        qRound(
            m_ambienceFadeOutActiveVolume
            * (1.0 - progress)));

    if (m_fadingAmbiencePlayer)
    {
        m_fadingAmbiencePlayer->setVolume(
            qRound(
                m_ambienceFadeOutFadingVolume
                * (1.0 - progress)));
    }

    if (progress >= 1.0)
        stopAmbienceImmediately();
}


// ============================================================================
// CROSSFADE
// ============================================================================

void AudioEngine::checkAmbienceCrossfade(
    QMediaPlayer *player)
{
    if (!player ||
        player != m_activeAmbiencePlayer ||
        m_ambienceFadeOutTimer->isActive() ||
        m_fadingAmbiencePlayer)
    {
        return;
    }

    const qint64 duration =
        player->duration();

    if (duration <= 0)
        return;

    if (duration - player->position()
        <= m_ambienceCrossfadeDuration)
    {
        startAmbienceCrossfade(player);
    }
}

void AudioEngine::startAmbienceCrossfade(
    QMediaPlayer *fadingPlayer)
{
    if (!fadingPlayer ||
        fadingPlayer != m_activeAmbiencePlayer ||
        m_fadingAmbiencePlayer)
    {
        return;
    }

    QMediaPlayer *nextPlayer =
        fadingPlayer == m_ambiencePlayerA
            ? m_ambiencePlayerB
            : m_ambiencePlayerA;

    nextPlayer->stop();

    nextPlayer->setMedia(
        fadingPlayer->currentMedia());

    nextPlayer->setPosition(0);
    nextPlayer->setVolume(0);

    m_fadingAmbiencePlayer =
        fadingPlayer;

    m_activeAmbiencePlayer =
        nextPlayer;

    m_ambienceCrossfadePosition = 0;

    nextPlayer->play();

    m_ambienceFadeInTimer->stop();

    m_ambienceCrossfadeElapsed.start();
    m_ambienceCrossfadeTimer->start();
}

void AudioEngine::updateAmbienceCrossfade()
{
    if (!m_activeAmbiencePlayer ||
        !m_fadingAmbiencePlayer)
    {
        m_ambienceCrossfadeTimer->stop();
        m_ambienceCrossfadePosition = 0;
        return;
    }

    m_ambienceCrossfadePosition =
        static_cast<int>(
            m_ambienceCrossfadeElapsed.elapsed());

    const double progress =
        m_ambienceCrossfadeDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(
                      m_ambienceCrossfadePosition)
                      / m_ambienceCrossfadeDuration)
            : 1.0;

    const int maximumVolume =
        ambienceTargetVolume();

    m_fadingAmbiencePlayer->setVolume(
        qRound(
            maximumVolume * (1.0 - progress)));

    m_activeAmbiencePlayer->setVolume(
        qRound(
            maximumVolume * progress));

    if (progress >= 1.0)
        finishAmbienceCrossfade();
}

void AudioEngine::finishAmbienceCrossfade()
{
    m_ambienceCrossfadeTimer->stop();
    m_ambienceCrossfadePosition = 0;

    if (m_fadingAmbiencePlayer)
    {
        m_fadingAmbiencePlayer->stop();
        m_fadingAmbiencePlayer->setVolume(0);
        m_fadingAmbiencePlayer = nullptr;
    }

    if (m_activeAmbiencePlayer)
    {
        m_activeAmbiencePlayer->setVolume(
            ambienceTargetVolume());
    }
}

void AudioEngine::handleAmbienceEndOfMedia(
    QMediaPlayer *player)
{
    if (player == m_fadingAmbiencePlayer)
    {
        if (m_ambienceFadeOutTimer->isActive())
        {
            player->setVolume(0);
            m_fadingAmbiencePlayer = nullptr;
            return;
        }

        finishAmbienceCrossfade();
        return;
    }

    if (player == m_activeAmbiencePlayer)
    {
        if (m_ambienceFadeOutTimer->isActive())
        {
            stopAmbienceImmediately();
            return;
        }

        player->setPosition(0);
        player->play();
    }
}
