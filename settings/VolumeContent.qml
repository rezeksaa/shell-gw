import QtQuick
import QtQuick.Layouts 1.12
import Quickshell
import QtQuick.Controls
import Quickshell.Io 
import Quickshell.Services.Pipewire

import "."
import "../components/"
import "../widgets/"
import "../settings/"
import "../popups/"
import "../panels/"
import "../shell/"

ColumnLayout {
    id: volumeContent
    
    spacing: 20
    Layout.fillWidth: true

    ColumnLayout {
        id: mixerList
        Layout.fillWidth: true
        spacing: 15

        PwNodeLinkTracker {
            id: linkTracker
            node: Pipewire.defaultAudioSink
        }

        
        MixerEntry {
            node: Pipewire.defaultAudioSink
            Layout.fillWidth: true
        }

        
        Repeater {
            model: linkTracker.linkGroups
            delegate: MixerEntry {
                required property PwLinkGroup modelData
                node: modelData.source
                Layout.fillWidth: true
            }
        }
    }

    
    
    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}