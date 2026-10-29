pragma Singleton
import QtQuick 2.0

/*
 * Maps canonical English sound keys to translated display labels.
 *
 * Rules:
 *  - Keys ("Wind", "Pink", "Delta"...) are used in state and engine
 *    logic and are NEVER translated.
 *  - Every qsTr() call for a sound name lives in THIS file only.
 *  - Callers: SoundNames.label(key)
 */
QtObject {
    function label(key) {
        switch (key) {
            // Brainwave bands
        case "Delta":       return qsTr("Delta")
        case "Delta/Theta": return qsTr("Delta/Theta")
        case "Theta":       return qsTr("Theta")
        case "Alpha":       return qsTr("Alpha")
        case "Beta":        return qsTr("Beta")
        case "Gamma":       return qsTr("Gamma")

            // Colored noise
        case "White":       return qsTr("White")
        case "Pink":        return qsTr("Pink")
        case "Brown":       return qsTr("Brown")
        case "Grey":        return qsTr("Grey")

            // Ambience
        case "Wind":        return qsTr("Wind")
        case "Waves":       return qsTr("Waves")
        case "Crickets":    return qsTr("Crickets")
        case "Stream":      return qsTr("Stream")
        case "Rain":        return qsTr("Rain")
        case "Birds":       return qsTr("Birds")
        case "Fire":        return qsTr("Fire")
        case "Chimes":      return qsTr("Chimes")
        case "Sailing":     return qsTr("Sailing")
        case "Lake":        return qsTr("Lake")

            // General UI text
        case "Ambient mix":                 return qsTr("Ambient mix")
        case "Start your sound mix": return qsTr("Start your sound mix")
        case "Individual experiences may vary.": return qsTr("Individual experiences may vary.")

        default:            return key
        }
    }
}
