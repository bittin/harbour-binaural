#ifndef AUDIOENGINE_H
#define AUDIOENGINE_H

#include <QObject>
#include <QAudioOutput>
#include <QElapsedTimer>
#include <QTimer>
#include <QString>

#include "ambiencechannel.h"
#include "pcmchannel.h"

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

    // Ambience implementation.
    void stopAmbiencesImmediately();
    void updateAmbienceState();

    // Colored-noise volume.
    void applyPendingColoredNoiseVolume();
    int coloredNoiseTargetVolume() const;

    // Sleep timer.
    QTimer *m_sleepTimerFadeTimer;
    QElapsedTimer m_sleepTimerFadeElapsed;

    double m_sleepTimerBinauralStartVolume;
    int m_sleepTimerAmbienceStartVolumes[MaxAmbienceChannels];
    double m_sleepTimerColoredNoiseStartVolume;

    // PCM playback channels (own output, generator, fade-out).
    PcmChannel *m_binauralChannel;
    PcmChannel *m_noiseChannel;

    // Generators (parameter access only; lifetime owned by PcmChannel).
    BinauralGenerator *m_binauralGenerator;
    ColoredNoiseGenerator *m_noiseGenerator;

    // Three independent ambience channels.
    AmbienceChannel *m_ambienceChannels[MaxAmbienceChannels];

    // Colored-noise volume debounce timer.
    QTimer *m_coloredNoiseVolumeTimer;

    // Audio settings.
    double m_beatFrequency;

    int m_binauralVolume;
    int m_ambienceVolume;
    int m_coloredNoiseVolume;

    QString m_currentColoredNoise;

    qint64 m_sleepTimerLastAmbienceUpdate = 0;
};

#endif
