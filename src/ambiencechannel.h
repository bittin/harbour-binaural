#ifndef AMBIENCECHANNEL_H
#define AMBIENCECHANNEL_H

#include <QObject>
#include <QElapsedTimer>
#include <QMediaPlayer>
#include <QString>
#include <QTimer>

class QMediaContent;

// ============================================================================
// AMBIENCE CHANNEL
// ============================================================================

/*
 * Plays and loops a single ambience sound with fade-in, fade-out and
 * seamless loop crossfading. AudioEngine owns up to
 * AudioEngine::MaxAmbienceChannels of these.
 */

class AmbienceChannel : public QObject
{
    Q_OBJECT

public:
    explicit AmbienceChannel(QObject *parent = nullptr);
    ~AmbienceChannel() override;

    bool start(const QString &fileName);
    void pause();
    void stop();            // fades out, then emits finished()
    void resume();
    void stopImmediately();

    bool isPlaying() const;
    bool isPaused() const;

    QString fileName() const;

    // Volume 0..100, debounced (applied after VolumeUpdateInterval)
    void setVolume(int volume);

    // Sleep timer support: scales the current playback volume by
    // (startVolume * factor), without touching the channel volume
    void applySleepVolume(int startVolume, double factor);

signals:
    // Emitted on any playing/paused state change
    void stateChanged();

    // Emitted once the fade-out following stop() has completed
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

    // Players (two, for seamless loop crossfading)
    QMediaPlayer *m_playerA;
    QMediaPlayer *m_playerB;

    QMediaPlayer *m_activePlayer;
    QMediaPlayer *m_fadingPlayer;

    // Fade and volume timers
    QTimer *m_fadeInTimer;
    QTimer *m_crossfadeTimer;
    QTimer *m_fadeOutTimer;
    QTimer *m_volumeTimer;

    // Fade timing
    QElapsedTimer m_crossfadeElapsed;
    QElapsedTimer m_fadeOutElapsed;

    // Audio settings
    int m_volume;            // 0..100
    QString m_fileName;

    // Fade positions
    int m_fadeInPosition;
    int m_crossfadePosition;

    // Fade-out starting volumes
    int m_fadeOutActiveVolume;
    int m_fadeOutFadingVolume;

    // Set while stop() is fading out
    bool m_stopping;
};

#endif
