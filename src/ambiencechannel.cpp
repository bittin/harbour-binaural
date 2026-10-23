#include "ambiencechannel.h"

#include <QDebug>
#include <QMediaContent>
#include <QUrl>
#include <QtMath>

namespace
{
    const int AmbienceFadeInDuration = 200;
    const int AmbienceFadeOutDuration = 200;
    const int AmbienceCrossfadeDuration = 8000;

    const int FadeInterval = 15;
    const int VolumeUpdateInterval = 50;

    const QString AmbienceBasePath =
        QStringLiteral(
            "file:///usr/share/harbour-binaural/sounds/");

    // MASTER VOLUME Adjuster Ambience Noise
    const double AmbienceMasterFactor = 0.6;
}

// ============================================================================
// AMBIENCE CHANNEL
// ============================================================================

AmbienceChannel::AmbienceChannel(QObject *parent)
    : QObject(parent),
      m_playerA(new QMediaPlayer(this)),
      m_playerB(new QMediaPlayer(this)),
      m_activePlayer(nullptr),
      m_fadingPlayer(nullptr),
      m_fadeInTimer(new QTimer(this)),
      m_crossfadeTimer(new QTimer(this)),
      m_fadeOutTimer(new QTimer(this)),
      m_volumeTimer(new QTimer(this)),
      m_volume(50),
      m_fadeInPosition(0),
      m_crossfadePosition(0),
      m_fadeOutActiveVolume(0),
      m_fadeOutFadingVolume(0),
      m_stopping(false)
{
    m_fadeInTimer->setInterval(FadeInterval);
    m_crossfadeTimer->setInterval(FadeInterval);
    m_fadeOutTimer->setInterval(FadeInterval);

    m_volumeTimer->setInterval(VolumeUpdateInterval);
    m_volumeTimer->setSingleShot(true);

    connectPlayer(m_playerA);
    connectPlayer(m_playerB);

    connect(m_fadeInTimer, &QTimer::timeout,
            this, this { updateFadeIn(); });

    connect(m_crossfadeTimer, &QTimer::timeout,
            this, this { updateCrossfade(); });

    connect(m_fadeOutTimer, &QTimer::timeout,
            this, this { updateFadeOut(); });

    connect(m_volumeTimer, &QTimer::timeout,
            this, this { applyPendingVolume(); });

    m_playerA->setVolume(0);
    m_playerB->setVolume(0);
}

AmbienceChannel::~AmbienceChannel()
{
    stopImmediately();
}

// ============================================================================
// STATE
// ============================================================================

bool AmbienceChannel::isPlaying() const
{
    return m_activePlayer &&
           m_activePlayer->state() == QMediaPlayer::PlayingState;
}

bool AmbienceChannel::isPaused() const
{
    return m_activePlayer &&
           m_activePlayer->state() == QMediaPlayer::PausedState;
}

QString AmbienceChannel::fileName() const
{
    return m_fileName;
}

// ============================================================================
// PLAYBACK
// ============================================================================

bool AmbienceChannel::start(const QString &fileName)
{
    const QUrl mediaUrl = QUrl(AmbienceBasePath + fileName);

    if (!mediaUrl.isValid())
        return false;

    stopImmediately();

    m_fileName = fileName;

    m_activePlayer = m_playerA;

    m_activePlayer->setMedia(mediaUrl);
    m_activePlayer->setVolume(0);

    m_fadeInPosition = 0;

    m_activePlayer->play();

    m_fadeInTimer->start();

    emit stateChanged();

    return true;
}

void AmbienceChannel::pause()
{
    if (!m_activePlayer ||
        m_activePlayer->state() != QMediaPlayer::PlayingState)
        return;

    m_fadeInTimer->stop();
    m_crossfadeTimer->stop();
    m_fadeOutTimer->stop();

    m_activePlayer->pause();

    if (m_fadingPlayer)
        m_fadingPlayer->pause();

    emit stateChanged();
}

void AmbienceChannel::resume()
{
    if (isPaused())
        m_activePlayer->play();
}

void AmbienceChannel::stop()
{
    if (!m_activePlayer)
        return;

    if (m_fadeOutTimer->isActive())
        return;

    m_fadeInTimer->stop();
    m_crossfadeTimer->stop();

    m_fadeOutActiveVolume = m_activePlayer->volume();

    m_fadeOutFadingVolume = m_fadingPlayer
        ? m_fadingPlayer->volume()
        : 0;

    m_stopping = true;

    m_fadeOutElapsed.start();
    m_fadeOutTimer->start();
}

void AmbienceChannel::stopImmediately()
{
    m_fadeInTimer->stop();
    m_crossfadeTimer->stop();
    m_fadeOutTimer->stop();
    m_volumeTimer->stop();

    m_playerA->stop();
    m_playerB->stop();

    m_playerA->setVolume(0);
    m_playerB->setVolume(0);

    m_activePlayer = nullptr;
    m_fadingPlayer = nullptr;

    m_fadeInPosition = 0;
    m_crossfadePosition = 0;

    m_fadeOutActiveVolume = 0;
    m_fadeOutFadingVolume = 0;

    m_stopping = false;

    emit stateChanged();
}

// ============================================================================
// VOLUME
// ============================================================================

void AmbienceChannel::setVolume(int volume)
{
    m_volume = qBound(0, volume, 100);

    m_volumeTimer->start();
}

int AmbienceChannel::targetVolume() const
{
    return qRound(m_volume * AmbienceMasterFactor);
}

void AmbienceChannel::applyPendingVolume()
{
    if (m_activePlayer &&
        !m_fadeInTimer->isActive() &&
        !m_crossfadeTimer->isActive() &&
        !m_fadeOutTimer->isActive())
    {
        m_activePlayer->setVolume(targetVolume());
    }
}

void AmbienceChannel::applySleepVolume(
    int startVolume, double factor)
{
    if (m_activePlayer)
    {
        m_activePlayer->setVolume(
            qRound(startVolume * factor));
    }

    if (m_fadingPlayer)
        m_fadingPlayer->setVolume(0);
}

// ============================================================================
// FADE IN / FADE OUT
// ============================================================================

void AmbienceChannel::updateFadeIn()
{
    if (!m_activePlayer)
    {
        m_fadeInTimer->stop();
        return;
    }

    m_fadeInPosition += FadeInterval;

    const double progress =
        AmbienceFadeInDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(m_fadeInPosition)
                      / AmbienceFadeInDuration)
            : 1.0;

    const int maximumVolume = targetVolume();

    m_activePlayer->setVolume(
        qRound(maximumVolume * progress));

    if (progress >= 1.0)
    {
        m_activePlayer->setVolume(maximumVolume);

        m_fadeInTimer->stop();
        m_fadeInPosition = 0;
    }
}

void AmbienceChannel::updateFadeOut()
{
    if (!m_activePlayer)
    {
        m_fadeOutTimer->stop();
        return;
    }

    const double progress =
        AmbienceFadeOutDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(m_fadeOutElapsed.elapsed())
                      / AmbienceFadeOutDuration)
            : 1.0;

    m_activePlayer->setVolume(
        qRound(m_fadeOutActiveVolume * (1.0 - progress)));

    if (m_fadingPlayer)
    {
        m_fadingPlayer->setVolume(
            qRound(m_fadeOutFadingVolume * (1.0 - progress)));
    }

    if (progress >= 1.0)
    {
        stopImmediately();

        if (m_stopping)
        {
            m_stopping = false;
            emit finished();
        }
    }
}

// ============================================================================
// CROSSFADE
// ============================================================================

void AmbienceChannel::checkCrossfade(QMediaPlayer *player)
{
    if (!player || player != m_activePlayer ||
        m_fadeOutTimer->isActive() || m_fadingPlayer)
    {
        return;
    }

    const qint64 duration = player->duration();

    if (duration <= 0)
        return;

    if (duration - player->position()
        <= AmbienceCrossfadeDuration)
    {
        startCrossfade(player);
    }
}

void AmbienceChannel::startCrossfade(
    QMediaPlayer *fadingPlayer)
{
    if (!fadingPlayer || fadingPlayer != m_activePlayer ||
        m_fadingPlayer)
    {
        return;
    }

    QMediaPlayer *nextPlayer =
        fadingPlayer == m_playerA
            ? m_playerB
            : m_playerA;

    nextPlayer->stop();

    nextPlayer->setMedia(fadingPlayer->currentMedia());

    nextPlayer->setPosition(0);
    nextPlayer->setVolume(0);

    m_fadingPlayer = fadingPlayer;
    m_activePlayer = nextPlayer;

    m_crossfadePosition = 0;

    nextPlayer->play();

    m_fadeInTimer->stop();

    m_crossfadeElapsed.start();
    m_crossfadeTimer->start();
}

void AmbienceChannel::updateCrossfade()
{
    if (!m_activePlayer || !m_fadingPlayer)
    {
        m_crossfadeTimer->stop();
        m_crossfadePosition = 0;
        return;
    }

    m_crossfadePosition =
        static_cast<int>(m_crossfadeElapsed.elapsed());

    const double progress =
        AmbienceCrossfadeDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(m_crossfadePosition)
                      / AmbienceCrossfadeDuration)
            : 1.0;

    const int maximumVolume = targetVolume();

    m_fadingPlayer->setVolume(
        qRound(maximumVolume * (1.0 - progress)));

    m_activePlayer->setVolume(
        qRound(maximumVolume * progress));

    if (progress >= 1.0)
        finishCrossfade();
}

void AmbienceChannel::finishCrossfade()
{
    m_crossfadeTimer->stop();
    m_crossfadePosition = 0;

    if (m_fadingPlayer)
    {
        m_fadingPlayer->stop();
        m_fadingPlayer->setVolume(0);
        m_fadingPlayer = nullptr;
    }

    if (m_activePlayer)
        m_activePlayer->setVolume(targetVolume());
}

void AmbienceChannel::handleEndOfMedia(QMediaPlayer *player)
{
    if (player == m_fadingPlayer)
    {
        if (m_fadeOutTimer->isActive())
        {
            player->setVolume(0);
            m_fadingPlayer = nullptr;
            return;
        }

        finishCrossfade();
        return;
    }

    if (player == m_activePlayer)
    {
        if (m_fadeOutTimer->isActive())
        {
            stopImmediately();

            if (m_stopping)
            {
                m_stopping = false;
                emit finished();
            }

            return;
        }

        player->setPosition(0);
        player->play();
    }
}

// ============================================================================
// PLAYER CONNECTIONS
// ============================================================================

void AmbienceChannel::connectPlayer(QMediaPlayer *player)
{
    connect(player,
            &QMediaPlayer::positionChanged,
            this,
            this, player
            {
                checkCrossfade(player);
            });

    connect(player,
            &QMediaPlayer::mediaStatusChanged,
            this,
            this, player
            {
                if (status == QMediaPlayer::EndOfMedia)
                {
                    handleEndOfMedia(player);
                }
                else if (status ==
                         QMediaPlayer::InvalidMedia)
                {
                    qWarning()
                        << "AmbienceChannel: invalid ambience:"
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
        player
        {
            qWarning()
                << "AmbienceChannel: ambience error:"
                << error
                << player->errorString();
        });

    connect(player,
            &QMediaPlayer::stateChanged,
            this,
            this, player
            {
                if (state !=
                        QMediaPlayer::PlayingState ||
                    player != m_activePlayer ||
                    m_crossfadeTimer->isActive() ||
                    m_fadeOutTimer->isActive())
                {
                    emit stateChanged();
                    return;
                }

                if (!m_fadeInTimer->isActive())
                    player->setVolume(targetVolume());
            });
}
