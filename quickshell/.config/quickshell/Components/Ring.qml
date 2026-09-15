// Mini arc gauge for the bar (cpu, memory, volume). QtQuick.Shapes renders on
// the GPU with the curve renderer, so no MSAA is needed for a clean edge and
// nothing is rasterised on the CPU when the value changes — a Canvas would
// re-paint and re-upload a texture on every sample.
import QtQuick
import QtQuick.Shapes
import qs.Theme

Item {
    id: root

    property real value: 0             // 0..1; negative = no reading (track only)
    property int size: Theme.iconSize
    property real thickness: 2
    property color color: Theme.accent
    property color trackColor: Theme.outline

    readonly property real shownValue: Math.max(0, Math.min(1, value))

    implicitWidth: size
    implicitHeight: size

    Behavior on value {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easeStandard }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.thickness
            strokeColor: root.trackColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - root.thickness / 2
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeWidth: root.thickness
            strokeColor: root.color
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - root.thickness / 2
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 360 * root.shownValue
            }
        }
    }
}
