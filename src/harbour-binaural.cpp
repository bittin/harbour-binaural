#include <QtQuick>
#include <QQmlEngine>
#include <QQuickView>
#include <QScopedPointer>
#include <sailfishapp.h>

#include "audioengine.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    qmlRegisterType<AudioEngine>("Binaural", 1, 0, "AudioEngine");

    qmlRegisterSingletonType(
        QUrl(SailfishApp::pathTo("qml/pages/components/SoundNames.qml")),
        "Binaural", 1, 0, "SoundNames");

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->setSource(SailfishApp::pathTo("qml/harbour-binaural.qml"));
    view->show();

    return app->exec();
}
