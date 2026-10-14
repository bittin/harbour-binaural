/****************************************************************************
** Meta object code from reading C++ file 'audioengine.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.6.3)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "src/audioengine.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'audioengine.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.6.3. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
struct qt_meta_stringdata_AudioEngine_t {
    QByteArrayData data[30];
    char stringdata0[416];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_AudioEngine_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_AudioEngine_t qt_meta_stringdata_AudioEngine = {
    {
QT_MOC_LITERAL(0, 0, 11), // "AudioEngine"
QT_MOC_LITERAL(1, 12, 14), // "playingChanged"
QT_MOC_LITERAL(2, 27, 0), // ""
QT_MOC_LITERAL(3, 28, 20), // "fadeOutForSleepTimer"
QT_MOC_LITERAL(4, 49, 5), // "start"
QT_MOC_LITERAL(5, 55, 4), // "stop"
QT_MOC_LITERAL(6, 60, 14), // "resumeBinaural"
QT_MOC_LITERAL(7, 75, 13), // "pauseBinaural"
QT_MOC_LITERAL(8, 89, 16), // "setFrequencyBand"
QT_MOC_LITERAL(9, 106, 4), // "band"
QT_MOC_LITERAL(10, 111, 11), // "setAmbience"
QT_MOC_LITERAL(11, 123, 8), // "ambience"
QT_MOC_LITERAL(12, 132, 13), // "pauseAmbience"
QT_MOC_LITERAL(13, 146, 12), // "stopAmbience"
QT_MOC_LITERAL(14, 159, 14), // "resumeAmbience"
QT_MOC_LITERAL(15, 174, 15), // "setColoredNoise"
QT_MOC_LITERAL(16, 190, 5), // "noise"
QT_MOC_LITERAL(17, 196, 17), // "pauseColoredNoise"
QT_MOC_LITERAL(18, 214, 16), // "stopColoredNoise"
QT_MOC_LITERAL(19, 231, 18), // "resumeColoredNoise"
QT_MOC_LITERAL(20, 250, 17), // "setBinauralVolume"
QT_MOC_LITERAL(21, 268, 6), // "volume"
QT_MOC_LITERAL(22, 275, 17), // "setAmbienceVolume"
QT_MOC_LITERAL(23, 293, 21), // "setColoredNoiseVolume"
QT_MOC_LITERAL(24, 315, 15), // "binauralPlaying"
QT_MOC_LITERAL(25, 331, 15), // "ambiencePlaying"
QT_MOC_LITERAL(26, 347, 19), // "coloredNoisePlaying"
QT_MOC_LITERAL(27, 367, 14), // "binauralPaused"
QT_MOC_LITERAL(28, 382, 14), // "ambiencePaused"
QT_MOC_LITERAL(29, 397, 18) // "coloredNoisePaused"

    },
    "AudioEngine\0playingChanged\0\0"
    "fadeOutForSleepTimer\0start\0stop\0"
    "resumeBinaural\0pauseBinaural\0"
    "setFrequencyBand\0band\0setAmbience\0"
    "ambience\0pauseAmbience\0stopAmbience\0"
    "resumeAmbience\0setColoredNoise\0noise\0"
    "pauseColoredNoise\0stopColoredNoise\0"
    "resumeColoredNoise\0setBinauralVolume\0"
    "volume\0setAmbienceVolume\0setColoredNoiseVolume\0"
    "binauralPlaying\0ambiencePlaying\0"
    "coloredNoisePlaying\0binauralPaused\0"
    "ambiencePaused\0coloredNoisePaused"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_AudioEngine[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
      18,   14, // methods
       6,  134, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    0,  104,    2, 0x06 /* Public */,

 // methods: name, argc, parameters, tag, flags
       3,    0,  105,    2, 0x02 /* Public */,
       4,    0,  106,    2, 0x02 /* Public */,
       5,    0,  107,    2, 0x02 /* Public */,
       6,    0,  108,    2, 0x02 /* Public */,
       7,    0,  109,    2, 0x02 /* Public */,
       8,    1,  110,    2, 0x02 /* Public */,
      10,    1,  113,    2, 0x02 /* Public */,
      12,    0,  116,    2, 0x02 /* Public */,
      13,    0,  117,    2, 0x02 /* Public */,
      14,    0,  118,    2, 0x02 /* Public */,
      15,    1,  119,    2, 0x02 /* Public */,
      17,    0,  122,    2, 0x02 /* Public */,
      18,    0,  123,    2, 0x02 /* Public */,
      19,    0,  124,    2, 0x02 /* Public */,
      20,    1,  125,    2, 0x02 /* Public */,
      22,    1,  128,    2, 0x02 /* Public */,
      23,    1,  131,    2, 0x02 /* Public */,

 // signals: parameters
    QMetaType::Void,

 // methods: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::QString,    9,
    QMetaType::Void, QMetaType::QString,   11,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::QString,   16,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int,   21,
    QMetaType::Void, QMetaType::Int,   21,
    QMetaType::Void, QMetaType::Int,   21,

 // properties: name, type, flags
      24, QMetaType::Bool, 0x00495001,
      25, QMetaType::Bool, 0x00495001,
      26, QMetaType::Bool, 0x00495001,
      27, QMetaType::Bool, 0x00495001,
      28, QMetaType::Bool, 0x00495001,
      29, QMetaType::Bool, 0x00495001,

 // properties: notify_signal_id
       0,
       0,
       0,
       0,
       0,
       0,

       0        // eod
};

void AudioEngine::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        AudioEngine *_t = static_cast<AudioEngine *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->playingChanged(); break;
        case 1: _t->fadeOutForSleepTimer(); break;
        case 2: _t->start(); break;
        case 3: _t->stop(); break;
        case 4: _t->resumeBinaural(); break;
        case 5: _t->pauseBinaural(); break;
        case 6: _t->setFrequencyBand((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 7: _t->setAmbience((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 8: _t->pauseAmbience(); break;
        case 9: _t->stopAmbience(); break;
        case 10: _t->resumeAmbience(); break;
        case 11: _t->setColoredNoise((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 12: _t->pauseColoredNoise(); break;
        case 13: _t->stopColoredNoise(); break;
        case 14: _t->resumeColoredNoise(); break;
        case 15: _t->setBinauralVolume((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 16: _t->setAmbienceVolume((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 17: _t->setColoredNoiseVolume((*reinterpret_cast< int(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        void **func = reinterpret_cast<void **>(_a[1]);
        {
            typedef void (AudioEngine::*_t)();
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&AudioEngine::playingChanged)) {
                *result = 0;
                return;
            }
        }
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty) {
        AudioEngine *_t = static_cast<AudioEngine *>(_o);
        Q_UNUSED(_t)
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< bool*>(_v) = _t->isBinauralPlaying(); break;
        case 1: *reinterpret_cast< bool*>(_v) = _t->isAmbiencePlaying(); break;
        case 2: *reinterpret_cast< bool*>(_v) = _t->isColoredNoisePlaying(); break;
        case 3: *reinterpret_cast< bool*>(_v) = _t->isBinauralPaused(); break;
        case 4: *reinterpret_cast< bool*>(_v) = _t->isAmbiencePaused(); break;
        case 5: *reinterpret_cast< bool*>(_v) = _t->isColoredNoisePaused(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
    } else if (_c == QMetaObject::ResetProperty) {
    }
#endif // QT_NO_PROPERTIES
}

const QMetaObject AudioEngine::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_AudioEngine.data,
      qt_meta_data_AudioEngine,  qt_static_metacall, Q_NULLPTR, Q_NULLPTR}
};


const QMetaObject *AudioEngine::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *AudioEngine::qt_metacast(const char *_clname)
{
    if (!_clname) return Q_NULLPTR;
    if (!strcmp(_clname, qt_meta_stringdata_AudioEngine.stringdata0))
        return static_cast<void*>(const_cast< AudioEngine*>(this));
    return QObject::qt_metacast(_clname);
}

int AudioEngine::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 18)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 18;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 18)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 18;
    }
#ifndef QT_NO_PROPERTIES
   else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyDesignable) {
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyScriptable) {
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyStored) {
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyEditable) {
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyUser) {
        _id -= 6;
    }
#endif // QT_NO_PROPERTIES
    return _id;
}

// SIGNAL 0
void AudioEngine::playingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, Q_NULLPTR);
}
QT_END_MOC_NAMESPACE
