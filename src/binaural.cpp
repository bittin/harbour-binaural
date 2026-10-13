#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QGuiApplication>
#include <QLocale>
#include <QQmlEngine>
#include <QQuickView>
#include <QTranslator>
#include <sailfishapp.h>

#include "audioengine.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Register the audio engine for use in QML.
    qmlRegisterType<AudioEngine>("Binaural", 1, 0, "AudioEngine");

    // Expose sound names as a QML singleton.
    qmlRegisterSingletonType(
        QUrl(SailfishApp::pathTo("qml/pages/components/SoundNames.qml")),
        "Binaural", 1, 0, "SoundNames");

    // Load the translation matching the system language (e.g. de.qm).
    QTranslator translator;
    const QString language = QLocale::system().name().left(2);

    translator.load(
        "harbour-binaural-" + language,
        SailfishApp::pathTo("translations").toString());

    app.installTranslator(&translator);

    // Load and display the main QML interface.
    QQuickView *view = SailfishApp::createView();
    view->setSource(SailfishApp::pathTo("qml/harbour-binaural.qml"));
    view->show();

    return app.exec();
}
