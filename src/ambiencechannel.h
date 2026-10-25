#ifndef AMBIENCECHANNEL_H
#define AMBIENCECHANNEL_H

#include <QObject>
#include <QMediaPlayer>
#include <QTimer>
#include <QString>

class AmbienceChannel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool playing READ isPlaying NOTIFY stateChanged)
    Q_PROPERTY(bool paused READ isPaused NOTIFY stateChanged)
    Q_PROPERTY(QString fileName READ fileName NOTIFY stateChanged)
    Q_PROPERTY(int currentVolume READ currentVolume NOTIFY stateChanged)

public:
    explicit AmbienceChannel(QObject *parent = nullptr);
    ~AmbienceChannel() override;

    bool isPlaying() const;
    bool isPaused() const;
    QString fileName() const;
    int currentVolume() const;
    int targetVolume() const;

    bool start(const QString &fileName);
    void pause();
    void resume();
    void stop();
    void stopImmediately();
    void setVolume(int volume);

    void applySleepVolume(int startVolume, double factor);

signals:
    void stateChanged();
    void finished();

private:
    void connectPlayer(QMediaPlayer *player);
    void applyPendingVolume();

    void updateFadeIn();
    void updateFadeOut();

    void checkCrossfade(QMediaPlayer *player);
    void startCrossfade(QMediaPlayer *fadingPlayer);
    void updateCrossfade();
    void finishCrossfade();
    void handleEndOfMedia(QMediaPlayer *player);

    QMediaPlayer *m_playerA;
    QMediaPlayer *m_playerB;
    QMediaPlayer *m_activePlayer;
    QMediaPlayer *m_fadingPlayer;

    QTimer *m_fadeInTimer;
    QTimer *m_crossfadeTimer;
    QTimer *m_fadeOutTimer;
    QTimer *m_volumeTimer;

    QString m_fileName;

    int m_volume;

    int m_fadeInPosition;
    int m_crossfadePosition;
    int m_fadeOutPosition;

    int m_fadeOutActiveVolume;
    int m_fadeOutFadingVolume;

    bool m_stopping;
    bool m_paused;
    bool m_resumeFadeIn;
    bool m_resumeCrossfade;

};

#endif
