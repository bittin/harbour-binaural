#ifndef AUDIOENGINE_H
#define AUDIOENGINE_H

#include <QObject>
#include <QAudioOutput>
#include <QElapsedTimer>
#include <QTimer>
#include <QString>

#include "ambiencechannel.h"

class BinauralGenerator;
class ColoredNoiseGenerator;

class AudioEngine : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool binauralPlaying
               READ isBinauralPlaying
               NOTIFY playingChanged)

    Q_PROPERTY(bool ambiencePlaying
               READ isAmbiencePlaying
               NOTIFY playingChanged)

    Q_PROPERTY(bool coloredNoisePlaying
               READ isColoredNoisePlaying
               NOTIFY playingChanged)

    Q_PROPERTY(bool binauralPaused
               READ isBinauralPaused
               NOTIFY playingChanged)

    Q_PROPERTY(bool ambiencePaused
               READ isAmbiencePaused
               NOTIFY playingChanged)

    Q_PROPERTY(bool coloredNoisePaused
               READ isColoredNoisePaused
               NOTIFY playingChanged)

public:
    static constexpr int MaxAmbienceChannels = 3;

    explicit AudioEngine(QObject *parent = nullptr);
    ~AudioEngine() override;

    bool isBinauralPlaying() const;
    bool isAmbiencePlaying() const;
    bool isColoredNoisePlaying() const;

    bool isBinauralPaused() const;
    bool isAmbiencePaused() const;
    bool isColoredNoisePaused() const;

    Q_INVOKABLE void fadeOutForSleepTimer();

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void resumeBinaural();
    Q_INVOKABLE void pauseBinaural();
    Q_INVOKABLE void setFrequencyBand(const QString &band);

    // Ambience controls.
    Q_INVOKABLE void setAmbience(const QString &ambience);
    Q_INVOKABLE void pauseAmbience();
    Q_INVOKABLE void stopAmbience();
    Q_INVOKABLE void stopAmbienceByName(const QString &ambience);
    Q_INVOKABLE void resumeAmbience();

    Q_INVOKABLE void setColoredNoise(const QString &noise);
    Q_INVOKABLE void pauseColoredNoise();
    Q_INVOKABLE void stopColoredNoise();
    Q_INVOKABLE void resumeColoredNoise();

    Q_INVOKABLE void setBinauralVolume(int volume);
    Q_INVOKABLE void setAmbienceVolume(int volume);
    Q_INVOKABLE void setColoredNoiseVolume(int volume);

signals:
    void playingChanged();

private:
    void updatePlayingState();
    // Shared PCM output setup (binaural + colored noise).
    bool resolvePcmFormat(QAudioFormat &format,
                          QAudioDeviceInfo &device,
                          const QString &context);

    // Binaural implementation.
    void updateBinauralFadeIn();
    void updateBinauralFadeOut();
    void stopBinauralImmediately();

    // Ambience implementation.
    void stopAmbiencesImmediately();
    void updateAmbienceState();

    // Colored-noise implementation.
    void updateColoredNoiseFadeOut();
    void stopColoredNoiseImmediately();
    void applyPendingColoredNoiseVolume();
    int coloredNoiseTargetVolume() const;

    // Sleep timer.
    QTimer *m_sleepTimerFadeTimer;
    QElapsedTimer m_sleepTimerFadeElapsed;

    double m_sleepTimerBinauralStartVolume;
    int m_sleepTimerAmbienceStartVolumes[MaxAmbienceChannels];
    double m_sleepTimerColoredNoiseStartVolume;

    // Binaural output.
    QAudioOutput *m_audioOutput;
    BinauralGenerator *m_generator;

    // Three independent ambience channels.
    AmbienceChannel *m_ambienceChannels[MaxAmbienceChannels];

    // Colored-noise output.
    QAudioOutput *m_coloredNoiseOutput;
    ColoredNoiseGenerator *m_coloredNoiseGenerator;

    // Binaural timers.
    QTimer *m_binauralFadeTimer;
    QTimer *m_binauralFadeOutTimer;

    // Colored-noise timers.
    QTimer *m_coloredNoiseFadeOutTimer;
    QTimer *m_coloredNoiseVolumeTimer;

    // Audio settings.
    double m_beatFrequency;

    int m_binauralVolume;
    int m_ambienceVolume;
    int m_coloredNoiseVolume;

    // Fade state.
    int m_binauralFadeInPosition;

    double m_binauralFadeOutStartVolume;
    double m_coloredNoiseFadeOutStartVolume;

    QElapsedTimer m_binauralFadeOutElapsed;
    QElapsedTimer m_coloredNoiseFadeOutElapsed;

    QString m_currentColoredNoise;
};

#endif // AUDIOENGINE_H
