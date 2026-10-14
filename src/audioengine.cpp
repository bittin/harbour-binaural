#include "audioengine.h"

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

    const double CarrierFrequency = 200.0;
    // MASTER VOLUME Binaural
    const double BinauralAmplitude = 13000.0;

    const int BinauralFadeInDuration = 0;
    const int BinauralFadeOutDuration = 0;

    const int AmbienceFadeInDuration = 200;
    const int AmbienceCrossfadeDuration = 8000;
    const int AmbienceFadeOutDuration = 200;

    const int ColoredNoiseFadeOutDuration = 200;

    const int SleepTimerFadeOutDuration = 5000;

    const int FadeInterval = 15;
    const int VolumeUpdateInterval = 50;
}


// ============================================================================
// BINAURAL GENERATOR
// ============================================================================

class AudioGenerator : public QIODevice
{
public:
    explicit AudioGenerator(QObject *parent = nullptr)
        : QIODevice(parent),
          m_sampleRate(DefaultSampleRate),
          m_leftPhase(0.0),
          m_rightPhase(0.0),
          m_beatFrequency(10.0)
    {
    }

    void start()
    {
        open(QIODevice::ReadOnly);
    }

    void stop()
    {
        close();
        m_leftPhase = 0.0;
        m_rightPhase = 0.0;
    }

    void setBeatFrequency(double frequency)
    {
        m_beatFrequency = qMax(0.0, frequency);
    }

    void setSampleRate(int sampleRate)
    {
        if (sampleRate > 0)
            m_sampleRate = sampleRate;
    }

protected:
    qint64 readData(char *data, qint64 maxlen) override
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

    qint64 writeData(const char *, qint64) override
    {
        return 0;
    }

private:
    double m_sampleRate;
    double m_leftPhase;
    double m_rightPhase;
    double m_beatFrequency;
};


// ============================================================================
// COLORED NOISE GENERATOR
// ============================================================================

class ColoredNoiseGenerator : public QIODevice
{
public:
    enum NoiseType
    {
        WhiteNoise = 0,
        PinkNoise,
        BrownNoise,
        GreyNoise
    };

    explicit ColoredNoiseGenerator(QObject *parent = nullptr)
        : QIODevice(parent),
          m_sampleRate(48000),
          m_channelCount(2),
          m_noiseType(WhiteNoise)
    {
        resetNoiseState();
    }

    void setSampleRate(int sampleRate)
    {
        if (sampleRate > 0)
            m_sampleRate = sampleRate;
    }

    int sampleRate() const
    {
        return m_sampleRate;
    }

    void setChannelCount(int channelCount)
    {
        if (channelCount > 0 && channelCount <= 2)
            m_channelCount = channelCount;
    }

    int channelCount() const
    {
        return m_channelCount;
    }

    void setNoiseType(NoiseType type)
    {
        if (m_noiseType == type)
            return;

        m_noiseType = type;
        resetNoiseState();
    }

    NoiseType noiseType() const
    {
        return m_noiseType;
    }

    void start()
    {
        resetNoiseState();
        open(QIODevice::ReadOnly);
    }

    void stop()
    {
        close();
    }

protected:
    qint64 readData(char *data, qint64 maxlen) override
    {
        if (!data || maxlen <= 0)
            return 0;

        const qint64 frameSize =
            static_cast<qint64>(m_channelCount) *
            static_cast<qint64>(sizeof(qint16));

        if (frameSize <= 0)
            return 0;

        const qint64 frameCount =
            maxlen / frameSize;

        if (frameCount <= 0)
            return 0;

        qint16 *samples =
            reinterpret_cast<qint16 *>(data);

        for (qint64 frame = 0;
             frame < frameCount;
             ++frame)
        {
            for (int channel = 0;
                 channel < m_channelCount;
                 ++channel)
            {
                double value = 0.0;

                switch (m_noiseType)
                {
                case WhiteNoise:
                    value = nextWhite(channel);
                    break;

                case PinkNoise:
                    value = nextPink(channel);
                    break;

                case BrownNoise:
                    value = nextBrown(channel);
                    break;

                case GreyNoise:
                    value = nextGrey(channel);
                    break;
                }

                /*
                 * Final safety limiter.
                 */
                value *= noiseGain();

                value = qBound(-1.0, value, 1.0);

                samples[
                        frame * m_channelCount + channel
                        ] =
                        static_cast<qint16>(
                            // MASTER VOLUME Colored Noise
                            value * 16000.0);
            }
        }

        return frameCount * frameSize;
    }

    qint64 writeData(const char *, qint64) override
    {
        return 0;
    }

private:

    /*
     * Per-noise-type loudness calibration.
     *
     * Different noise colors produce different perceived loudness
     * at the same numerical signal level. These fixed gains provide
     * a practical balance between the four noise types without
     * requiring real-time loudness normalization.
     */
    double noiseGain() const
    {
        switch (m_noiseType)
        {
        case WhiteNoise:
            return 0.40;

        case PinkNoise:
            return 1.00;

        case BrownNoise:
            return 1.00;

        case GreyNoise:
            return 0.80;
        }

        return 1.0;
    }

    void resetNoiseState()
    {
        for (int channel = 0;
             channel < 2;
             ++channel)
        {
            /*
             * Independent deterministic seed for
             * left and right channels.
             */
            m_randomState[channel] =
                0x12345678u +
                static_cast<quint32>(
                    channel * 0x13579BDFu);

            /*
             * Pink noise filter state.
             */
            for (int i = 0; i < 7; ++i)
                m_pinkState[channel][i] = 0.0;

            /*
             * Brown noise state.
             */
            m_brownState[channel] = 0.0;

            /*
             * Grey noise filter state.
             */
            m_greyLow[channel] = 0.0;
            m_greyMid[channel] = 0.0;
            m_greyHigh[channel] = 0.0;

            m_whiteFiltered[channel] = 0.0;
        }
    }

    /*
     * ================================================================
     * WHITE NOISE
     * ================================================================
     *
     * Starts from a raw pseudo-random source and applies
     * lightweight smoothing to reduce the aggressive character
     * of unfiltered white noise.
     *
     * The result remains broadband but is intentionally softened
     * for more comfortable long-duration listening.
     */

    /*
     * Raw white-noise source.
     *
     * Provides an unsmoothed random signal for algorithms such as
     * Brown noise that require direct integration of white noise.
     * A deterministic, independent state is maintained per channel.
     */
    double nextRawWhite(int channel)
    {
        /*
         * 32-bit linear congruential generator.
         */
        m_randomState[channel] =
            1664525u *
            m_randomState[channel]
            + 1013904223u;

        const quint32 randomValue =
            m_randomState[channel];

        /*
         * Convert unsigned 32-bit value to
         * approximately [-1.0, +1.0].
         */
        return
            (static_cast<double>(randomValue) /
             2147483648.0) - 1.0;
    }

    double nextWhite(int channel)
    {
        const double white =
            nextRawWhite(channel);

        /*
         * Smooth the White noise to reduce the
         * aggressive high-frequency character.
         */
        m_whiteFiltered[channel] =
            m_whiteFiltered[channel] * 0.82
            + white * 0.18;

        return m_whiteFiltered[channel] * 0.82;
    }

    /*
     * ================================================================
     * PINK NOISE
     * ================================================================
     *
     * Approximately 1/f power spectrum.
     *
     * Roughly -3 dB per octave.
     *
     * Uses a Paul Kellet-style filter built from the smoothed
     * white-noise source to produce a stable pink-noise approximation.
     */
    double nextPink(int channel)
    {
        const double white =
            nextWhite(channel);

        double *state =
            m_pinkState[channel];

        state[0] =
            0.99886 * state[0]
            + white * 0.0555179;

        state[1] =
            0.99332 * state[1]
            + white * 0.0750759;

        state[2] =
            0.96900 * state[2]
            + white * 0.1538520;

        state[3] =
            0.86650 * state[3]
            + white * 0.3104856;

        state[4] =
            0.55000 * state[4]
            + white * 0.5329522;

        state[5] =
            -0.7616 * state[5]
            - white * 0.0168980;

        const double pink =
            state[0] +
            state[1] +
            state[2] +
            state[3] +
            state[4] +
            state[5] +
            state[6] +
            white * 0.5362;

        state[6] =
            white * 0.115926;

        /*
         * Gain compensation.
         */
        return pink * 0.11;
    }

    /*
     * ================================================================
     * BROWN NOISE
     * ================================================================
     *
     * Approximately 1/f^2 power spectrum.
     *
     * Roughly -6 dB per octave.
     *
     * Uses leaky integration of a raw white-noise source to create
     * smooth low-frequency variations while preventing excessive
     * DC drift. The internal output is gain-compensated for perceived
     * loudness before the final output calibration.
     */
    double nextBrown(int channel)
    {
        const double white =
            nextRawWhite(channel);

        double &state =
            m_brownState[channel];

        /*
         * Leaky integration of raw white noise.
         *
         * The leakage prevents unlimited DC drift while
         * retaining the characteristic slow movement of
         * Brown noise.
         */
        state =
            state * 0.995
            + white * 0.018;

        /*
         * Keep the internal state within a safe range.
         */
        state =
            qBound(-1.0, state, 1.0);

        /*
         * Perceived loudness compensation.
         */
        return state * 2.8;
    }

    /*
     * ================================================================
     * GREY NOISE
     * ================================================================
     *
     * Grey noise is psychoacoustic rather than having
     * one universally fixed mathematical spectrum.
     *
     * This implementation starts from pink noise and applies
     * separate low-, mid-, and high-frequency shaping to create
     * a smoother, more perceptually balanced approximation.
     *
     * The result is intended as a practical approximation of
     * equal-loudness-oriented grey noise rather than an exact
     * reproduction of a specific psychoacoustic standard.
     */
    double nextGrey(int channel)
    {
        /*
         * Start from Pink noise.
         *
         * Grey noise is commonly described as a noise signal
         * shaped according to human hearing sensitivity.
         */
        const double pink =
            nextPink(channel);

        double &low =
            m_greyLow[channel];

        double &mid =
            m_greyMid[channel];

        double &high =
            m_greyHigh[channel];

        /*
         * Low-frequency component.
         *
         * Slow component retains some of the lower-frequency
         * energy of Pink noise.
         */
        low =
            low * 0.985
            + pink * 0.015;

        /*
         * Mid-frequency component.
         *
         * This region is deliberately given more weight,
         * reflecting the greater sensitivity of human hearing
         * in the mid-frequency range.
         */
        mid =
            mid * 0.80
            + pink * 0.20;

        /*
         * High-frequency component.
         *
         * Faster response keeps the high-frequency contribution
         * controlled without making Grey sound harsh.
         */
        high =
            high * 0.45
            + pink * 0.55;

        /*
         * Psychoacoustic weighting.
         *
         * Keep the low frequencies restrained, emphasize the
         * useful midrange, and retain a smaller high-frequency
         * contribution.
         */
        const double grey =
            low * 0.25
            + mid * 0.60
            + high * 0.15;

        return grey * 2.4;
    }

private:
    int m_sampleRate;
    int m_channelCount;

    NoiseType m_noiseType;

    quint32 m_randomState[2];

    double m_pinkState[2][7];

    double m_brownState[2];

    double m_greyLow[2];
    double m_greyMid[2];
    double m_greyHigh[2];

    double m_whiteFiltered[2];
};

// ============================================================================
// AUDIO ENGINE
// ============================================================================

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent),
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
      m_sleepTimerFadeTimer(new QTimer(this)),

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

      m_sleepTimerBinauralStartVolume(0.0),
      m_sleepTimerAmbienceStartVolume(0.0),
      m_sleepTimerColoredNoiseStartVolume(0.0),

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

bool AudioEngine::isBinauralPlaying() const
{
    return m_audioOutput &&
           m_audioOutput->state() == QAudio::ActiveState;
}

bool AudioEngine::isBinauralPaused() const
{
    return m_audioOutput &&
           m_audioOutput->state() == QAudio::SuspendedState;
}

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

void AudioEngine::resumeBinaural()
{
    if (isBinauralPaused())
        m_audioOutput->resume();
}

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
// FREQUENCY
// ============================================================================

void AudioEngine::setFrequencyBand(const QString &band)
{
    if (band == "Delta")
        m_beatFrequency = 2.0;
    else if (band == "Delta/Theta")
        m_beatFrequency = 4.0;
    else if (band == "Theta")
        m_beatFrequency = 6.0;
    else if (band == "Alpha")
        m_beatFrequency = 10.0;
    else if (band == "Beta")
        m_beatFrequency = 20.0;
    else if (band == "Gamma")
        m_beatFrequency = 40.0;
    else
        return;

    if (m_generator)
        m_generator->setBeatFrequency(
            m_beatFrequency);
}


// ============================================================================
// VOLUME
// ============================================================================

void AudioEngine::setBinauralVolume(int volume)
{
    m_binauralVolume =
        qBound(0, volume, 100);

    if (m_audioOutput &&
        !m_binauralFadeTimer->isActive() &&
        !m_binauralFadeOutTimer->isActive())
    {
        m_audioOutput->setVolume(
            m_binauralVolume / 100.0);
    }
}

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
    QUrl mediaUrl;

    if (ambience == "Wind")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/wind.mp3");
    }
    else if (ambience == "Rain")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/rain.mp3");
    }
    else if (ambience == "Stream")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/stream.mp3");
    }
    else if (ambience == "Waves")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/waves.mp3");
    }
    else if (ambience == "Lake")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/lake.mp3");
    }
    else if (ambience == "Sailing")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/sailing.mp3");
    }
    else if (ambience == "Birds")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/birds.mp3");
    }
    else if (ambience == "Crickets")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/crickets.mp3");
    }
    else if (ambience == "Chimes")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/chimes.mp3");
    }
    else if (ambience == "Fire")
    {
        mediaUrl = QUrl(
            "file:///usr/share/harbour-binaural/"
            "sounds/fire.mp3");
    }
    else
    {
        return;
    }

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

void AudioEngine::start()
{
    if (m_audioOutput)
    {
        /*
         * Starting while a fade-out is running cancels
         * the fade-out and restores the requested volume.
         */
        if (m_binauralFadeOutTimer->isActive())
        {
            m_binauralFadeOutTimer->stop();

            m_audioOutput->setVolume(
                m_binauralVolume / 100.0);
        }

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
                << "AudioEngine: compatible binaural "
                   "PCM output format not available";
            return;
        }

        format = nearest;
    }

    m_generator =
        new AudioGenerator(this);

    m_generator->setBeatFrequency(
        m_beatFrequency);

    m_generator->setSampleRate(
        format.sampleRate());

    m_generator->start();

    m_audioOutput =
        new QAudioOutput(device, format, this);

    m_audioOutput->setVolume(
        m_binauralVolume / 100.0);

    connect(
        m_audioOutput,
        &QAudioOutput::stateChanged,
        this,
        [this](QAudio::State)
        {
            updatePlayingState();
        });

    m_audioOutput->start(m_generator);

    updatePlayingState();
}

void AudioEngine::pauseBinaural()
{
    if (!m_audioOutput ||
        m_audioOutput->state() != QAudio::ActiveState)
        return;

    m_binauralFadeTimer->stop();
    m_binauralFadeOutTimer->stop();

    m_audioOutput->suspend();

    updatePlayingState();
}

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

void AudioEngine::stop()
{
    if (!m_audioOutput ||
        m_binauralFadeOutTimer->isActive())
    {
        return;
    }

    m_binauralFadeTimer->stop();

    m_binauralFadeOutStartVolume =
        m_audioOutput->volume();

    m_binauralFadeOutElapsed.start();

    m_binauralFadeOutTimer->start();
}

void AudioEngine::updateBinauralFadeIn()
{
    if (!m_audioOutput)
    {
        m_binauralFadeTimer->stop();
        return;
    }

    m_binauralFadeInPosition +=
        FadeInterval;

    const double progress =
        BinauralFadeInDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(
                      m_binauralFadeInPosition)
                      / BinauralFadeInDuration)
            : 1.0;

    m_audioOutput->setVolume(
        (m_binauralVolume / 100.0)
        * progress);

    if (progress >= 1.0)
    {
        m_audioOutput->setVolume(
            m_binauralVolume / 100.0);

        m_binauralFadeTimer->stop();
        m_binauralFadeInPosition = 0;
    }
}

void AudioEngine::updateBinauralFadeOut()
{
    if (!m_audioOutput)
    {
        m_binauralFadeOutTimer->stop();
        return;
    }

    const double progress =
        BinauralFadeOutDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(
                      m_binauralFadeOutElapsed.elapsed())
                      / BinauralFadeOutDuration)
            : 1.0;

    m_audioOutput->setVolume(
        m_binauralFadeOutStartVolume
        * (1.0 - progress));

    if (progress >= 1.0)
        stopBinauralImmediately();
}

void AudioEngine::stopBinauralImmediately()
{
    m_binauralFadeTimer->stop();
    m_binauralFadeOutTimer->stop();

    if (m_audioOutput)
    {
        m_audioOutput->stop();

        delete m_audioOutput;
        m_audioOutput = nullptr;
    }

    if (m_generator)
    {
        m_generator->stop();

        delete m_generator;
        m_generator = nullptr;
    }

    m_binauralFadeInPosition = 0;
    m_binauralFadeOutStartVolume = 0.0;

    updatePlayingState();
}
