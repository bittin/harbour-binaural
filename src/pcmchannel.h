#ifndef PCMCHANNEL_H
#define PCMCHANNEL_H

#include <QObject>
#include <QAudioOutput>
#include <QElapsedTimer>
#include <QTimer>
#include <QString>

#include <functional>

class QIODevice;
class QAudioDeviceInfo;
class QAudioFormat;

/*
 * Owns one PCM playback pipeline: a QAudioOutput fed by a
 * generator (QIODevice). Handles format negotiation, volume,
 * pause/resume, fade-out and teardown.
 *
 * The engine creates generators and hands them over; the channel
 * is then responsible for asking them for samples (or not).
 */

class PcmChannel : public QObject
{
    Q_OBJECT

public:
    explicit PcmChannel(const QString &name,
                        qreal initialVolume,
                        QObject *parent = nullptr);
    ~PcmChannel() override;

    bool isRunning() const;     // output exists (active or suspended)
    bool isPlaying() const;      // QAudio::ActiveState
    bool isPaused() const;       // QAudio::SuspendedState
    bool isFadingOut() const;

    qreal volume() const;

    /*
     * Resolves the 16-bit PCM format, calls configure(format)
     * so the caller can prepare the generator, then starts
     * playback. Takes ownership of generator on success.
     * Returns false if no usable output device/format exists.
     */
    bool start(QIODevice *generator,
               const std::function<void(const QAudioFormat &)> &configure);

    void pause();
    void resume();

    void setVolume(qreal volume);       // deferred while fading out
    void beginFadeOut(int durationMs);  // 0 = stop on next tick
    void cancelFadeOut();
    void stopImmediately();

signals:
    void stateChanged();
    void stopped();

private:
    void updateFadeOut();
    bool resolvePcmFormat(QAudioFormat &format,
                          QAudioDeviceInfo &device) const;

    QAudioOutput *m_output;
    QIODevice *m_generator;

    QTimer *m_fadeTimer;
    QElapsedTimer m_fadeElapsed;

    qreal m_volume;
    qreal m_fadeStartVolume;
    int m_fadeDuration;
    // True while a fade-out is running toward an intended stop.
    bool m_stopAfterFade;
    // Fade time already elapsed before the last pause.
    qint64 m_fadeElapsedBeforePause;

    QString m_name;
};

#endif
