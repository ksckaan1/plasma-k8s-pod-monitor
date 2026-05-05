import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    implicitWidth: 650
    implicitHeight: 350

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function (source, data) {
            var out = data["stdout"] || "";
            var err = data["stderr"] || "";
            disconnectSource(source);
            if (err && !out) {
                podModel.clear();
                errorText = err.trim();
                return;
            }
            errorText = "";
            parsePods(out);
            lastUpdated = Qt.formatTime(new Date(), "hh:mm:ss");
        }

        function run(cmd) {
            connectSource(cmd);
        }
    }

    property bool allNamespaces: Plasmoid.configuration.namespace.trim() === ""

    property string kubectlCmd: {
        var ns = Plasmoid.configuration.namespace.trim();
        var kc = Plasmoid.configuration.kubeconfig.trim();
        var base = kc !== "" ? "kubectl --kubeconfig=" + kc + " get pods" : "kubectl get pods";
        return ns !== "" ? base + " -n " + ns : base + " -A";
    }

    onKubectlCmdChanged: executable.run(kubectlCmd)

    Timer {
        interval: Plasmoid.configuration.interval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: executable.run(root.kubectlCmd)
    }

    ListModel {
        id: podModel
    }

    property string lastUpdated: "--:--:--"
    property string errorText: ""

    readonly property int colNamespace: 80
    readonly property int colName: 180
    readonly property int colReady: 55
    readonly property int colStatus: 90
    readonly property int colRestarts: 100
    readonly property int colAge: 60

    function parsePods(raw) {
        podModel.clear();
        var lines = raw.trim().split("\n");
        for (var i = 1; i < lines.length; i++) {
            var parts = lines[i].trim().split(/\s+/);
            if (root.allNamespaces) {
                if (parts.length < 6)
                    continue;
                var ns = parts[0];
                var name = parts[1];
                var ready = parts[2];
                var status = parts[3];
                var age = parts[parts.length - 1];
                var restarts = parts.slice(4, parts.length - 1).join(" ");
                podModel.append({
                    podNamespace: ns,
                    podName: name,
                    ready: ready,
                    status: status,
                    restarts: restarts,
                    age: age
                });
            } else {
                if (parts.length < 5)
                    continue;
                var name = parts[0];
                var ready = parts[1];
                var status = parts[2];
                var age = parts[parts.length - 1];
                var restarts = parts.slice(3, parts.length - 1).join(" ");
                podModel.append({
                    podNamespace: "",
                    podName: name,
                    ready: ready,
                    status: status,
                    restarts: restarts,
                    age: age
                });
            }
        }
    }

    fullRepresentation: Rectangle {
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Qt.rgba(0, 0, 0, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.08)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: root.errorText ? "#ef4444" : "#22c55e"
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0.3
                                duration: 900
                            }
                            NumberAnimation {
                                to: 1.0
                                duration: 900
                            }
                        }
                    }

                    Text {
                        text: {
                            var ns = Plasmoid.configuration.namespace.trim();
                            return ns !== "" ? ns + "  /  pods" : "all namespaces  /  pods";
                        }
                        font.pixelSize: 13
                        font.letterSpacing: 1.5
                        font.weight: Font.Medium
                        color: "#e2e8f0"
                        leftPadding: 6
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "↻  " + root.lastUpdated
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        color: Qt.rgba(1, 1, 1, 0.35)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.07)
                }

                Row {
                    Layout.fillWidth: true
                    leftPadding: 8
                    spacing: 0

                    Text {
                        visible: root.allNamespaces
                        width: root.colNamespace
                        text: "NAMESPACE"
                        font.pixelSize: 9
                        font.letterSpacing: 1.8
                        font.weight: Font.Medium
                        color: Qt.rgba(1, 1, 1, 0.30)
                    }

                    Repeater {
                        model: [
                            {
                                label: "NAME",
                                w: root.colName
                            },
                            {
                                label: "READY",
                                w: root.colReady
                            },
                            {
                                label: "STATUS",
                                w: root.colStatus
                            },
                            {
                                label: "RESTARTS",
                                w: root.colRestarts
                            },
                            {
                                label: "AGE",
                                w: root.colAge
                            }
                        ]
                        Text {
                            width: modelData.w
                            text: modelData.label
                            font.pixelSize: 9
                            font.letterSpacing: 1.8
                            font.weight: Font.Medium
                            color: Qt.rgba(1, 1, 1, 0.30)
                        }
                    }
                }

                Text {
                    visible: root.errorText !== ""
                    text: root.errorText
                    color: "#f87171"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: podModel
                    clip: true
                    spacing: 4

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 32
                        radius: 7
                        color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.03)
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            spacing: 0

                            Text {
                                visible: root.allNamespaces
                                width: root.colNamespace
                                text: model.podNamespace
                                font.pixelSize: 12
                                rightPadding: 4
                                font.family: "monospace"
                                color: "#818cf8"
                                elide: Text.ElideRight
                            }

                            Text {
                                width: root.colName
                                text: model.podName
                                font.pixelSize: 12
                                rightPadding: 4
                                font.family: "monospace"
                                color: "#cbd5e1"
                                elide: Text.ElideRight
                            }

                            Text {
                                width: root.colReady
                                text: model.ready
                                font.pixelSize: 12
                                font.family: "monospace"
                                color: {
                                    var p = model.ready.split("/");
                                    return p[0] === p[1] ? "#86efac" : "#fca5a5";
                                }
                            }

                            Row {
                                width: root.colStatus
                                spacing: 6
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: {
                                        if (model.status === "Running")
                                            return "#22c55e";
                                        if (model.status === "Completed")
                                            return "#38bdf8";
                                        if (model.status === "Pending")
                                            return "#f59e0b";
                                        if (model.status === "Error" || model.status === "CrashLoopBackOff")
                                            return "#ef4444";
                                        return "#94a3b8";
                                    }
                                }
                                Text {
                                    text: model.status
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    color: {
                                        if (model.status === "Running")
                                            return "#86efac";
                                        if (model.status === "Completed")
                                            return "#7dd3fc";
                                        if (model.status === "Pending")
                                            return "#fcd34d";
                                        if (model.status === "Error" || model.status === "CrashLoopBackOff")
                                            return "#fca5a5";
                                        return "#94a3b8";
                                    }
                                }
                            }

                            Text {
                                width: root.colRestarts
                                text: model.restarts
                                font.pixelSize: 12
                                font.family: "monospace"
                                color: parseInt(model.restarts) > 0 ? "#fcd34d" : "#64748b"
                                elide: Text.ElideRight
                            }

                            Text {
                                width: root.colAge
                                text: model.age
                                font.pixelSize: 12
                                font.family: "monospace"
                                color: "#64748b"
                            }
                        }
                    }
                }
            }
        }
    }
}
