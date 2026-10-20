#ifndef AUDIOENGINE_H
#define AUDIOENGINE_H

#include <QObject>
#include <QAudioOutput>
#include <QElapsedTimer>
#include <QMediaPlayer>
#include <QTimer>
#include <QString>

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
    explicit AudioEngine(QObject *parent = nullptr);
    ~AudioEngine();

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

    Q_INVOKABLE void setAmbience(const QString &ambience);
    Q_INVOKABLE void pauseAmbience();
    Q_INVOKABLE void stopAmbience();
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

    // Binaural
    void updateBinauralFadeIn();
    void updateBinauralFadeOut();
    void stopBinauralImmediately();

    // Ambience
    void connectAmbiencePlayer(QMediaPlayer *player);
    void updateAmbienceFadeIn();
    void checkAmbienceCrossfade(QMediaPlayer *player);
    void startAmbienceCrossfade(QMediaPlayer *fadingPlayer);
    void updateAmbienceCrossfade();
    void finishAmbienceCrossfade();
    void handleAmbienceEndOfMedia(QMediaPlayer *player);
    void updateAmbienceFadeOut();
    void stopAmbienceImmediately();

    // Colored noise
    void updateColoredNoiseFadeOut();
    void stopColoredNoiseImmediately();

    // Volume
    void applyPendingAmbienceVolume();
    void applyPendingColoredNoiseVolume();

    int ambienceTargetVolume() const;
    int coloredNoiseTargetVolume() const;

    // SleepTimer FadeOut
    QTimer *m_sleepTimerFadeTimer;
    QElapsedTimer m_sleepTimerFadeElapsed;

    double m_sleepTimerBinauralStartVolume;
    double m_sleepTimerAmbienceStartVolume;
    double m_sleepTimerColoredNoiseStartVolume;

private:
    QAudioOutput *m_audioOutput;
    BinauralGenerator *m_generator;

    QMediaPlayer *m_ambiencePlayerA;
    QMediaPlayer *m_ambiencePlayerB;

    QAudioOutput *m_coloredNoiseOutput;
    ColoredNoiseGenerator *m_coloredNoiseGenerator;

    QTimer *m_binauralFadeTimer;
    QTimer *m_ambienceFadeInTimer;
    QTimer *m_ambienceCrossfadeTimer;

    QTimer *m_binauralFadeOutTimer;
    QTimer *m_ambienceFadeOutTimer;
    QTimer *m_coloredNoiseFadeOutTimer;

    QTimer *m_ambienceVolumeTimer;
    QTimer *m_coloredNoiseVolumeTimer;

    QMediaPlayer *m_activeAmbiencePlayer;
    QMediaPlayer *m_fadingAmbiencePlayer;

    QElapsedTimer m_ambienceCrossfadeElapsed;
    QElapsedTimer m_binauralFadeOutElapsed;
    QElapsedTimer m_ambienceFadeOutElapsed;
    QElapsedTimer m_coloredNoiseFadeOutElapsed;

    double m_beatFrequency;

    int m_binauralVolume;
    int m_ambienceVolume;
    int m_coloredNoiseVolume;

    int m_binauralFadeInPosition;
    int m_ambienceFadeInPosition;
    int m_ambienceCrossfadePosition;

    int m_ambienceCrossfadeDuration;

    double m_binauralFadeOutStartVolume;
    double m_coloredNoiseFadeOutStartVolume;

    int m_ambienceFadeOutActiveVolume;
    int m_ambienceFadeOutFadingVolume;

    QString m_currentColoredNoise;
};

#endif
