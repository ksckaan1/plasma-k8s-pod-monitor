import QtQuick
import QtQuick.Controls
import org.kde.kirigami 2.20 as Kirigami

Kirigami.FormLayout {
    id: form

    property alias cfg_namespace: namespaceField.text
    property alias cfg_kubeconfig: kubeconfigField.text

    property string cfg_namespaceDefault: ""
    property string cfg_kubeconfigDefault: ""

    TextField {
        id: namespaceField
        Kirigami.FormData.label: "Namespace"
        placeholderText: "Leave empty for all namespaces"
    }

    TextField {
        id: kubeconfigField
        Kirigami.FormData.label: "Kubeconfig Path"
        placeholderText: "Leave empty for default kubeconfig"
    }
}
