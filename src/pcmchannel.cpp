#include "pcmchannel.h"

#include <QAudioDeviceInfo>
#include <QAudioFormat>
#include <QDebug>

namespace
{
    const int FadeInterval = 15;
}

// ============================================================================
// LIFECYCLE
// ============================================================================

PcmChannel::PcmChannel(const QString &name,
                       qreal initialVolume,
                       QObject *parent)
    : QObject(parent),
      m_output(nullptr),
      m_generator(nullptr),
      m_fadeTimer(new QTimer(this)),
      m_volume(initialVolume),
      m_fadeStartVolume(0.0),
      m_fadeDuration(0),
      m_stopAfterFade(false),
      m_fadeElapsedBeforePause(0),
      m_name(name)
{
    m_fadeTimer->setInterval(FadeInterval);

    connect(m_fadeTimer,
            &QTimer::timeout,
            this,
            &PcmChannel::updateFadeOut);
}

PcmChannel::~PcmChannel()
{
    stopImmediately();
}

// ============================================================================
// STATE
// ============================================================================

bool PcmChannel::isRunning() const
{
    return m_output != nullptr;
}

bool PcmChannel::isPlaying() const
{
    return m_output
        && m_output->state() == QAudio::ActiveState;
}

bool PcmChannel::isPaused() const
{
    return m_output
        && m_output->state() == QAudio::SuspendedState;
}

bool PcmChannel::isFadingOut() const
{
    return m_fadeTimer->isActive();
}

qreal PcmChannel::volume() const
{
    return m_output ? m_output->volume() : 0.0;
}

// ============================================================================
// START
// ============================================================================

bool PcmChannel::start(
    QIODevice *generator,
    const std::function<void(const QAudioFormat &)> &configure)
{
    if (m_output)
        return true;

    QAudioFormat format;
    QAudioDeviceInfo device;

    if (!resolvePcmFormat(format, device))
        return false;

    configure(format);

    m_generator = generator;

    m_output = new QAudioOutput(device, format, this);

    m_output->setVolume(m_volume);

    connect(m_output,
            &QAudioOutput::stateChanged,
            this,
            &PcmChannel::stateChanged);

    m_output->start(m_generator);

    return true;
}

// ============================================================================
// PAUSE / RESUME
// ============================================================================

void PcmChannel::pause()
{
    if (!m_output
        || m_output->state() != QAudio::ActiveState)
        return;

    // Preserve a running fade-out across the pause so the
    // intended stop is not silently aborted.
    if (m_fadeTimer->isActive())
    {
        m_fadeElapsedBeforePause +=
                m_fadeElapsed.elapsed();
        m_fadeElapsed.invalidate();
    }

    m_fadeTimer->stop();

    m_output->suspend();
}

void PcmChannel::resume()
{
    // Continue an interrupted fade-out toward its stop.
    if (m_stopAfterFade && m_output)
    {
        m_fadeElapsed.start();
        m_fadeTimer->start();
        return;
    }

    if (isPaused())
        m_output->resume();
}

// ============================================================================
// VOLUME / FADE-OUT / STOP
// ============================================================================

void PcmChannel::setVolume(qreal volume)
{
    m_volume = volume;

    if (m_output && !m_fadeTimer->isActive())
        m_output->setVolume(volume);
}

void PcmChannel::beginFadeOut(int durationMs)
{
    if (!m_output)
        return;

    if (m_fadeTimer->isActive())
        return;

    m_fadeStartVolume = m_output->volume();
    m_fadeDuration = durationMs;
    m_stopAfterFade = true;
    m_fadeElapsedBeforePause = 0;

    m_fadeElapsed.start();
    m_fadeTimer->start();
}

void PcmChannel::cancelFadeOut()
{
    m_fadeTimer->stop();
    m_stopAfterFade = false;
    m_fadeElapsedBeforePause = 0;
}

void PcmChannel::updateFadeOut()
{
    if (!m_output)
    {
        m_fadeTimer->stop();
        m_stopAfterFade = false;
        return;
    }

    const qint64 elapsed = m_fadeElapsedBeforePause
        + m_fadeElapsed.elapsed();

    const double progress =
        m_fadeDuration > 0
            ? qMin(1.0,
                   static_cast<double>(elapsed)
                       / m_fadeDuration)
            : 1.0;

    m_output->setVolume(
        m_fadeStartVolume * (1.0 - progress));

    if (progress >= 1.0)
        stopImmediately();
}

void PcmChannel::stopImmediately()
{
    m_fadeTimer->stop();
    m_stopAfterFade = false;
    m_fadeElapsedBeforePause = 0;

    if (m_output)
    {
        m_output->stop();

        delete m_output;
        m_output = nullptr;
    }

    if (m_generator)
    {
        // Close and delete the generator.
        m_generator->close();
        delete m_generator;
        m_generator = nullptr;
    }

    m_fadeStartVolume = 0.0;

    emit stopped();
    emit stateChanged();
}

// ============================================================================
// FORMAT NEGOTIATION
// ============================================================================

bool PcmChannel::resolvePcmFormat(
    QAudioFormat &format,
    QAudioDeviceInfo &device) const
{
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleSize(16);
    format.setCodec("audio/pcm");
    format.setByteOrder(QAudioFormat::LittleEndian);
    format.setSampleType(QAudioFormat::SignedInt);

    device = QAudioDeviceInfo::defaultOutputDevice();

    if (device.isNull())
    {
        qWarning() << "PcmChannel:" << m_name
                   << "no audio output device";
        return false;
    }

    if (device.isFormatSupported(format))
        return true;

    /*
     * Do not silently accept a nearest format with
     * another sample size/type.
     */
    const QAudioFormat nearest = device.nearestFormat(format);

    if (!nearest.isValid()
            || nearest.sampleSize() != 16
            || nearest.sampleType() != QAudioFormat::SignedInt
        || nearest.byteOrder() != QAudioFormat::LittleEndian)
    {
        qWarning() << "PcmChannel:" << m_name
                   << "no compatible 16-bit PCM output format";
        return false;
    }

    format = nearest;
    return true;
}
