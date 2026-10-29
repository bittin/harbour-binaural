#ifndef AMBIENCECHANNEL_H
#define AMBIENCECHANNEL_H

#include <QObject>
#include <QMediaPlayer>
#include <QElapsedTimer>
#include <QTimer>
#include <QString>

class AmbienceChannel : public QObject
{
    Q_OBJECT

public:
    explicit AmbienceChannel(QObject *parent = nullptr);
    ~AmbienceChannel() override;

    bool start(const QString &fileName);

    void pause();
    void stop();
    void resume();
    void stopImmediately();

    bool isPlaying() const;
    bool isPaused() const;
    bool isStopping() const;

    QString fileName() const;

    void setVolume(int volume);
    int currentVolume() const;

    void applySleepVolume(int startVolume, double factor);

signals:
    void stateChanged();
    void finished();

private:
    void connectPlayer(QMediaPlayer *player);

    void updateFadeIn();
    void updateFadeOut();
    void updateCrossfade();

    void checkCrossfade(QMediaPlayer *player);
    void startCrossfade(QMediaPlayer *fadingPlayer);
    void finishCrossfade();
    void handleEndOfMedia(QMediaPlayer *player);

    void applyPendingVolume();
    int targetVolume() const;

    QMediaPlayer *m_playerA;
    QMediaPlayer *m_playerB;

    QMediaPlayer *m_activePlayer;
    QMediaPlayer *m_fadingPlayer;

    QTimer *m_fadeInTimer;
    QTimer *m_crossfadeTimer;
    QTimer *m_fadeOutTimer;
    QTimer *m_volumeTimer;

    int m_volume;
    QString m_fileName;

    QElapsedTimer m_fadeInElapsed;
    QElapsedTimer m_crossfadeElapsed;
    qint64 m_fadeInElapsedBeforePause = 0;
    qint64 m_crossfadeElapsedBeforePause = 0;

    QElapsedTimer m_fadeElapsed;
    qint64 m_fadeElapsedBeforePause = 0;

    int m_fadeOutActiveVolume;
    int m_fadeOutFadingVolume;

    bool m_stopping;
    bool m_paused;

    bool m_resumeFadeIn;
    bool m_resumeCrossfade;

    double m_sleepFactor = 1.0;
};

#endif
