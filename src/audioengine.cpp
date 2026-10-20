#include "audioengine.h"
#include "binauralgenerator.h"
#include "colorednoisegenerator.h"

#include <QAudioDeviceInfo>
#include <QAudioFormat>
#include <QDebug>
#include <QMediaContent>
#include <QUrl>
#include <QtMath>
#include <cstring>

namespace
{
    const int DefaultSampleRate = 48000;
    const int ChannelCount = 2;
    const int SampleSize = 16;

    const int AmbienceFadeInDuration = 200;
    const int AmbienceCrossfadeDuration = 8000;
    const int AmbienceFadeOutDuration = 200;

    const int ColoredNoiseFadeOutDuration = 200;

    const int SleepTimerFadeOutDuration = 5000;

    const int FadeInterval = 15;
    const int VolumeUpdateInterval = 50;

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
// AUDIO ENGINE
// ============================================================================

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent),
      m_sleepTimerFadeTimer(new QTimer(this)),
      m_sleepTimerBinauralStartVolume(0.0),
      m_sleepTimerAmbienceStartVolume(0.0),
      m_sleepTimerColoredNoiseStartVolume(0.0),
      m_audioOutput(nullptr),
      m_generator(nullptr),
      m_ambiencePlayerA(new QMediaPlayer(this)),
      m_ambiencePlayerB(new QMediaPlayer(this)),
      m_coloredNoiseOutput(nullptr),
      m_coloredNoiseGenerator(nullptr),

      m_binauralFadeTimer(new QTimer(this)),
      m_ambienceFadeInTimer(new QTimer(this)),
      m_ambienceCrossfadeTimer(new QTimer(this)),

      m_binauralFadeOutTimer(new QTimer(this)),
      m_ambienceFadeOutTimer(new QTimer(this)),
      m_coloredNoiseFadeOutTimer(new QTimer(this)),

      m_ambienceVolumeTimer(new QTimer(this)),
      m_coloredNoiseVolumeTimer(new QTimer(this)),

      m_activeAmbiencePlayer(nullptr),
      m_fadingAmbiencePlayer(nullptr),

      m_beatFrequency(10.0),

      m_binauralVolume(50),
      m_ambienceVolume(50),
      m_coloredNoiseVolume(50),

      m_binauralFadeInPosition(0),
      m_ambienceFadeInPosition(0),
      m_ambienceCrossfadePosition(0),

      m_ambienceCrossfadeDuration(
          AmbienceCrossfadeDuration),

      m_binauralFadeOutStartVolume(0.0),
      m_coloredNoiseFadeOutStartVolume(0.0),

      m_ambienceFadeOutActiveVolume(0),
      m_ambienceFadeOutFadingVolume(0)
{
    m_binauralFadeTimer->setInterval(FadeInterval);
    m_ambienceFadeInTimer->setInterval(FadeInterval);
    m_ambienceCrossfadeTimer->setInterval(FadeInterval);

    m_binauralFadeOutTimer->setInterval(FadeInterval);
    m_ambienceFadeOutTimer->setInterval(FadeInterval);
    m_coloredNoiseFadeOutTimer->setInterval(FadeInterval);
    m_sleepTimerFadeTimer->setInterval(FadeInterval);

    m_ambienceVolumeTimer->setInterval(
        VolumeUpdateInterval);
    m_ambienceVolumeTimer->setSingleShot(true);

    m_coloredNoiseVolumeTimer->setInterval(
        VolumeUpdateInterval);
    m_coloredNoiseVolumeTimer->setSingleShot(true);

    connectAmbiencePlayer(m_ambiencePlayerA);
    connectAmbiencePlayer(m_ambiencePlayerB);

    connect(m_binauralFadeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateBinauralFadeIn();
            });

    connect(m_ambienceFadeInTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateAmbienceFadeIn();
            });

    connect(m_ambienceCrossfadeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateAmbienceCrossfade();
            });

    connect(m_binauralFadeOutTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateBinauralFadeOut();
            });

    connect(m_ambienceFadeOutTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateAmbienceFadeOut();
            });

    connect(m_coloredNoiseFadeOutTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateColoredNoiseFadeOut();
            });

    connect(m_sleepTimerFadeTimer, &QTimer::timeout, this, [this]()
    {
        const double progress =
            qMin(
                1.0,
                static_cast<double>(
                    m_sleepTimerFadeElapsed.elapsed())
                    / SleepTimerFadeOutDuration);

        const double factor = 1.0 - progress;

        if (m_audioOutput)
        {
            m_audioOutput->setVolume(
                m_sleepTimerBinauralStartVolume * factor);
        }

        if (m_activeAmbiencePlayer)
        {
            m_activeAmbiencePlayer->setVolume(
                static_cast<int>(
                    m_sleepTimerAmbienceStartVolume * factor));
        }

        if (m_fadingAmbiencePlayer)
        {
            m_fadingAmbiencePlayer->setVolume(0);
        }

        if (m_coloredNoiseOutput)
        {
            m_coloredNoiseOutput->setVolume(
                m_sleepTimerColoredNoiseStartVolume * factor);
        }

        if (progress >= 1.0)
        {
            m_sleepTimerFadeTimer->stop();

            stopBinauralImmediately();
            stopAmbienceImmediately();
            stopColoredNoiseImmediately();
        }
    });

    connect(m_ambienceVolumeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                applyPendingAmbienceVolume();
            });

    connect(m_coloredNoiseVolumeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                applyPendingColoredNoiseVolume();
            });

    m_ambiencePlayerA->setVolume(0);
    m_ambiencePlayerB->setVolume(0);
}


AudioEngine::~AudioEngine()
{
    stopBinauralImmediately();
    stopAmbienceImmediately();
    stopColoredNoiseImmediately();
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

bool AudioEngine::isColoredNoisePlaying() const
{
    return m_coloredNoiseOutput &&
           m_coloredNoiseOutput->state()
               == QAudio::ActiveState;
}

bool AudioEngine::isColoredNoisePaused() const
{
    return m_coloredNoiseOutput &&
           m_coloredNoiseOutput->state()
               == QAudio::SuspendedState;
}

void AudioEngine::updatePlayingState()
{
    emit playingChanged();
}


// ============================================================================
// RESUME
// ============================================================================

void AudioEngine::resumeAmbience()
{
    if (isAmbiencePaused())
        m_activeAmbiencePlayer->play();
}

void AudioEngine::resumeColoredNoise()
{
    if (isColoredNoisePaused())
        m_coloredNoiseOutput->resume();
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

void AudioEngine::setColoredNoiseVolume(int volume)
{
    m_coloredNoiseVolume =
        qBound(0, volume, 100);

    m_coloredNoiseVolumeTimer->start();
}

int AudioEngine::ambienceTargetVolume() const
{
    return qRound(
                // MASTER VOLUME Adjuster Ambience Noise
        m_ambienceVolume * 0.6);
}

int AudioEngine::coloredNoiseTargetVolume() const
{
    return qRound(
                // MASTER VOLUME Adjuster Colored Noise
        m_coloredNoiseVolume * 0.4);
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

void AudioEngine::applyPendingColoredNoiseVolume()
{
    if (m_coloredNoiseOutput &&
        !m_coloredNoiseFadeOutTimer->isActive())
    {
        m_coloredNoiseOutput->setVolume(
            static_cast<qreal>(
                coloredNoiseTargetVolume()) / 100.0);
    }
}


// ============================================================================
// AMBIENCE
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


// ============================================================================
// COLORED NOISE
// ============================================================================

void AudioEngine::setColoredNoise(
    const QString &noise)
{
    ColoredNoiseGenerator::NoiseType type;

    if (noise == "White")
    {
        type = ColoredNoiseGenerator::WhiteNoise;
    }
    else if (noise == "Pink")
    {
        type = ColoredNoiseGenerator::PinkNoise;
    }
    else if (noise == "Brown")
    {
        type = ColoredNoiseGenerator::BrownNoise;
    }
    else if (noise == "Grey")
    {
        type = ColoredNoiseGenerator::GreyNoise;
    }
    else
    {
        return;
    }

    /*
     * If noise is already running, only change the
     * algorithm. The audio stream itself remains alive.
     */
    if (m_coloredNoiseGenerator &&
        m_coloredNoiseOutput)
    {
        m_coloredNoiseFadeOutTimer->stop();

        m_coloredNoiseGenerator->setNoiseType(type);

        m_coloredNoiseOutput->setVolume(
            static_cast<qreal>(
                coloredNoiseTargetVolume()) / 100.0);

        m_currentColoredNoise = noise;

        updatePlayingState();
        return;
    }

    QAudioFormat format;

    format.setSampleRate(DefaultSampleRate);
    format.setChannelCount(ChannelCount);
    format.setSampleSize(SampleSize);
    format.setCodec("audio/pcm");
    format.setByteOrder(QAudioFormat::LittleEndian);
    format.setSampleType(QAudioFormat::SignedInt);

    const QAudioDeviceInfo device =
        QAudioDeviceInfo::defaultOutputDevice();

    if (device.isNull())
    {
        qWarning()
            << "AudioEngine: no audio output device";
        return;
    }

    /*
     * The generator produces signed 16-bit PCM.
     * Do not silently accept a nearest format with
     * another sample size/type.
     */
    if (!device.isFormatSupported(format))
    {
        QAudioFormat nearest =
            device.nearestFormat(format);

        if (!nearest.isValid() ||
            nearest.sampleSize() != SampleSize ||
            nearest.sampleType()
                != QAudioFormat::SignedInt ||
            nearest.byteOrder()
                != QAudioFormat::LittleEndian)
        {
            qWarning()
                << "AudioEngine: compatible 16-bit PCM "
                   "output format not available";
            return;
        }

        format = nearest;
    }

    m_coloredNoiseGenerator =
        new ColoredNoiseGenerator(this);

    m_coloredNoiseGenerator->setSampleRate(
        format.sampleRate());

    m_coloredNoiseGenerator->setChannelCount(
        format.channelCount());

    m_coloredNoiseGenerator->setNoiseType(type);

    m_coloredNoiseGenerator->start();

    m_coloredNoiseOutput =
        new QAudioOutput(device, format, this);

    m_coloredNoiseOutput->setVolume(
        static_cast<qreal>(
            coloredNoiseTargetVolume()) / 100.0);

    connect(
        m_coloredNoiseOutput,
        &QAudioOutput::stateChanged,
        this,
        [this](QAudio::State)
        {
            updatePlayingState();
        });

    m_currentColoredNoise = noise;

    m_coloredNoiseOutput->start(
        m_coloredNoiseGenerator);

    updatePlayingState();
}

void AudioEngine::pauseColoredNoise()
{
    if (!m_coloredNoiseOutput ||
        m_coloredNoiseOutput->state()
            != QAudio::ActiveState)
        return;

    m_coloredNoiseFadeOutTimer->stop();

    m_coloredNoiseOutput->suspend();

    updatePlayingState();
}

void AudioEngine::stopColoredNoise()
{
    if (!m_coloredNoiseOutput)
    {
        stopColoredNoiseImmediately();
        return;
    }

    if (m_coloredNoiseFadeOutTimer->isActive())
        return;

    m_coloredNoiseFadeOutStartVolume =
        m_coloredNoiseOutput->volume();

    m_coloredNoiseFadeOutElapsed.start();

    m_coloredNoiseFadeOutTimer->start();
}

void AudioEngine::updateColoredNoiseFadeOut()
{
    if (!m_coloredNoiseOutput)
    {
        m_coloredNoiseFadeOutTimer->stop();
        return;
    }

    const double progress =
        ColoredNoiseFadeOutDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(
                      m_coloredNoiseFadeOutElapsed.elapsed())
                      / ColoredNoiseFadeOutDuration)
            : 1.0;

    m_coloredNoiseOutput->setVolume(
        m_coloredNoiseFadeOutStartVolume
        * (1.0 - progress));

    if (progress >= 1.0)
        stopColoredNoiseImmediately();
}

void AudioEngine::stopColoredNoiseImmediately()
{
    m_coloredNoiseFadeOutTimer->stop();
    m_coloredNoiseVolumeTimer->stop();

    if (m_coloredNoiseOutput)
    {
        m_coloredNoiseOutput->stop();

        delete m_coloredNoiseOutput;
        m_coloredNoiseOutput = nullptr;
    }

    if (m_coloredNoiseGenerator)
    {
        m_coloredNoiseGenerator->stop();

        delete m_coloredNoiseGenerator;
        m_coloredNoiseGenerator = nullptr;
    }

    m_currentColoredNoise.clear();
    m_coloredNoiseFadeOutStartVolume = 0.0;

    updatePlayingState();
}


// ============================================================================
// BINAURAL
// ============================================================================

void AudioEngine::fadeOutForSleepTimer()
{
    m_sleepTimerFadeTimer->stop();

    m_sleepTimerBinauralStartVolume =
        m_audioOutput
            ? m_audioOutput->volume()
            : 0.0;

    m_sleepTimerAmbienceStartVolume =
        m_activeAmbiencePlayer
            ? m_activeAmbiencePlayer->volume()
            : 0.0;

    m_sleepTimerColoredNoiseStartVolume =
        m_coloredNoiseOutput
            ? m_coloredNoiseOutput->volume()
            : 0.0;

    m_sleepTimerFadeElapsed.start();
    m_sleepTimerFadeTimer->start();
}
