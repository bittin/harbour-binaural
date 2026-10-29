# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed


# The name of your application
TARGET = harbour-binaural


CONFIG += sailfishapp


# QtMultimedia for access to Sailfish's multimedia/audio APIs.
QT += multimedia


SOURCES += src/harbour-binaural.cpp \
    src/ambiencechannel.cpp \
    src/audioengine.cpp \
    src/audioengine_ambience.cpp \
    src/audioengine_binaural.cpp \
    src/audioengine_colorednoise.cpp \
    src/binauralgenerator.cpp \
    src/colorednoisegenerator.cpp \
    src/pcmchannel.cpp


DISTFILES += qml/harbour-binaural.qml \
    icons/216x216/harbour-binaural.png \
    qml/pages/CreditPage.qml \
    qml/pages/MainPage.qml \
    qml/cover/CoverPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/TimerPage.qml \
    qml/pages/components/AmbienceDrawer.qml \
    qml/pages/components/InfoBinauralPage.qml \
    qml/pages/components/InfoColoredPage.qml \
    qml/pages/components/PlaybackBar.qml \
    qml/pages/components/SoundNames.qml \
    qml/pages/components/VolumeIcon.qml \
    rpm/harbour-binaural.changes \
    rpm/harbour-binaural.changes.run.in \
    rpm/harbour-binaural.spec \
    qml/images/binaural-cover.svg \
    qml/images/icon-s-volume-1.svg \
    qml/images/icon-s-volume-2.svg \
    qml/images/icon-s-volume-3.svg \
    qml/images/icon-s-volume-4.svg \
    qml/images/icon-s-headset.svg \
    qml/images/image-binaural-graph.svg \
    qml/images/image-colornoise-graph.svg \
    translations/*.ts \
    harbour-binaural.desktop \
    sounds/wind.mp3 \
    sounds/crickets.mp3 \
    sounds/stream.mp3 \
    sounds/rain.mp3 \
    sounds/birds.mp3 \
    sounds/fire.mp3 \
    sounds/waves.mp3 \
    sounds/sailing.mp3 \
    sounds/lake.mp3 \
    sounds/chimes.mp3



SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172


# To disable building translations every time, comment out the
# following CONFIG line.
CONFIG += sailfishapp_i18n


TRANSLATIONS += translations/harbour-binaural-de.ts
TRANSLATIONS += translations/harbour-binaural-fr.ts
TRANSLATIONS += translations/harbour-binaural-it.ts
TRANSLATIONS += translations/harbour-binaural-sv.ts
TRANSLATIONS += translations/harbour-binaural-nb.ts
TRANSLATIONS += translations/harbour-binaural-nl.ts


HEADERS += \
    src/ambiencechannel.h \
    src/audioengine.h \
    src/binauralgenerator.h \
    src/colorednoisegenerator.h \
    src/pcmchannel.h


# Install the audio files as application data.
#
# qmake's install system puts the files into the same
# directory that AudioEngine expects at runtime.
ambient.files = sounds/wind.mp3 \
                sounds/waves.mp3 \
                sounds/crickets.mp3 \
                sounds/stream.mp3 \
                sounds/rain.mp3 \
                sounds/birds.mp3 \
                sounds/fire.mp3 \
                sounds/sailing.mp3 \
                sounds/lake.mp3 \
                sounds/chimes.mp3

ambient.path = /usr/share/harbour-binaural/sounds


INSTALLS += ambient
