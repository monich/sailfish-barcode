import QtQuick 2.0
import QtMultimedia 5.4
import Sailfish.Silica 1.0

import "../harbour"
import "../js/Utils.js" as Utils

VideoOutput {
    id: viewFinder

    anchors.fill: parent
    fillMode: VideoOutput.Stretch

    property size viewfinderResolution
    property bool showFocusArea: true
    property real digitalZoom: 1.0
    property bool invert
    property bool frontCamera
    readonly property bool mirrored: frontCamera && camera.deviceId == Utils.frontCameraId

    property size supportedWideResolution: Qt.size(0,0) // 4:3
    property size supportedNarrowResolution: Qt.size(0,0) // 16:9

    readonly property bool cameraActive: camera.cameraState === Camera.ActiveState
    readonly property bool flashOn: camera.flash.mode !== Camera.FlashOff
    // Not sure why not just camera.orientation but this makes the camera
    // behave similar to what it does for Jolla Camera
    readonly property int cameraOrientation: 360 - camera.orientation

    // Camera doesn't know its maximumDigitalZoom until cameraStatus becomes
    // Camera.ActiveStatus and doesn't emit maximumDigitalZoomChanged signal
    signal maximumDigitalZoom(var value)

    // Internal properties
    readonly property bool _tapFocusActive: focusTimer.running
    readonly property real _ratio_4_3: 4./3.
    readonly property real _ratio_16_9: 16./9.
    property bool _completed
    property bool _cameraSelected

    layer.enabled: invert
    layer.effect: HarbourInvertEffect {
        source: viewFinder
    }

    onOrientationChanged: {
        if (camera.cameraState !== Camera.UnloadedState) {
            reloadTimer.restart()
        }
    }

    onViewfinderResolutionChanged: {
        if (viewfinderResolution && camera.viewfinder.resolution !== viewfinderResolution) {
            if (camera.cameraState === Camera.UnloadedState) {
                camera.viewfinder.resolution = viewfinderResolution
            } else {
                reloadTimer.restart()
            }
        }
    }

    onDigitalZoomChanged: {
        if (camera.cameraStatus === Camera.ActiveStatus) {
            camera.digitalZoom = digitalZoom
        }
    }

    Component.onCompleted: {
        if (viewfinderResolution) {
            camera.viewfinder.resolution = viewfinderResolution
        }
        _completed = true
    }

    function turnFlashOn() {
        camera.flash.mode = Camera.FlashTorch
    }

    function turnFlashOff() {
        camera.flash.mode = Camera.FlashOff
    }

    function toggleFlash() {
        if (flashOn) {
            turnFlashOff()
        } else {
            turnFlashOn()
        }
    }

    function viewfinderToFramePoint(vx, vy) {
        var x = (vx - viewFinder.contentRect.x)/viewFinder.contentRect.width
        var y = (vy - viewFinder.contentRect.y)/viewFinder.contentRect.height
        switch (cameraOrientation) {
        case 90:  return Qt.point(y, 1 - x)
        case 180: return Qt.point(1 - x, 1 - y)
        case 270: return Qt.point(1 - y, x)
        default:  return Qt.point(x, y)
        }
    }

    function frameToViewfinderRect(rect) {
        var vx, vy, vw, vh
        switch (cameraOrientation) {
        case 90:
        case 270:
            vw = rect.height
            vh = rect.width
            break
        default:
            vw = rect.width
            vh = rect.height
            break
        }
        switch (cameraOrientation) {
        case 90:
            vx = 1 - rect.y - vw
            vy = rect.x
            break
        case 180:
            vx = 1 - rect.x - vw
            vy = 1 - rect.y - vh
            break
        case 270:
            vx = rect.y
            vy = 1 - rect.x - vh
            break
        default:
            vx = rect.x
            vy = rect.y
            break
        }
        return Qt.rect(viewFinder.contentRect.width * vx +  viewFinder.contentRect.x,
                       viewFinder.contentRect.height * vy + viewFinder.contentRect.y,
                       viewFinder.contentRect.width * vw, viewFinder.contentRect.height * vh)
    }

    source: Camera {
        id: camera

        flash.mode: Camera.FlashOff
        captureMode: Camera.CaptureStillImage
        videoRecorder.frameRate: 30
        imageProcessing.whiteBalanceMode: flashOn ?
            CameraImageProcessing.WhiteBalanceFlash :
            CameraImageProcessing.WhiteBalanceTungsten
        cameraState: (_completed && !reloadTimer.running) ?
            Camera.ActiveState : Camera.UnloadedState
        exposure {
            exposureCompensation: 1.0
            exposureMode: Camera.ExposureAuto
        }
        focus {
            focusMode: _tapFocusActive ? Camera.FocusAuto : Camera.FocusContinuous
            focusPointMode: _tapFocusActive ? Camera.FocusPointCustom : Camera.FocusPointAuto
        }
        onCameraStatusChanged: {
            if (cameraStatus === Camera.ActiveStatus) {
                if (!_cameraSelected) {
                    _cameraSelected = true

                    // Check all the available cameras
                    var defaultCameraId
                    for (var i = 0; i < QtMultimedia.availableCameras.length; i++) {
                        var device = QtMultimedia.availableCameras[i]
                        switch (device.position) {
                        case Camera.FrontFace:
                            if (!Utils.frontCameraId) {
                                Utils.frontCameraId = device.deviceId
                                console.log("Front camera", Utils.frontCameraId)
                            }
                            break
                        case Camera.BackFace:
                            if (!Utils.backCameraId) {
                                Utils.backCameraId = defaultCameraId = device.deviceId
                                console.log("Back camera", Utils.backCameraId)
                            }
                            break
                        default: // Unspecified or unknown position
                            if (!defaultCameraId) {
                                defaultCameraId = device.deviceId
                            }
                            break
                        }
                    }

                    // If there's no back camera, use the default one (if there is any)
                    if (!Utils.backCameraId && defaultCameraId) {
                        console.log("Default camera", Utils.defaultCameraId)
                        Utils.backCameraId = defaultCameraId
                    }

                    // Choose the camera
                    var deviceId = frontCamera ? Utils.frontCameraId : Utils.backCameraId
                    if (deviceId && camera.deviceId !== deviceId) {
                        camera.deviceId = deviceId
                        reloadTimer.restart()
                    }
                }

                // Camera doesn't emit maximumDigitalZoomChanged signal
                viewFinder.maximumDigitalZoom(maximumDigitalZoom)
                digitalZoom = viewFinder.digitalZoom
            }
            updateSupportedResolutions()
        }
        onCameraStateChanged: {
            if (cameraState === Camera.UnloadedState) {
                if (viewFinder.viewfinderResolution &&
                    viewFinder.viewfinderResolution !== viewfinder.resolution) {
                    viewfinder.resolution = viewFinder.viewfinderResolution
                }
            }
        }
        onError: {
            console.log(errorString)
            reloadTimer.restart()
        }
        Component.onCompleted: {
            if (frontCamera) {
                if (Utils.frontCameraId) {
                    deviceId = Utils.frontCameraId
                }
            } else if (Utils.backCameraId) {
                deviceId = Utils.backCameraId
            }
        }
        function updateSupportedResolutions() {
            var list = camera.supportedViewfinderResolutions()
            var max_4_3 = Qt.size(0,0)
            var max_16_9 = Qt.size(0,0)
            for (var i = 0; i < list.length; i++) {
                var size = list[i]
                var ratio = size.width / size.height
                if (ratio === _ratio_4_3) {
                    if (size.width > max_4_3.width) {
                        max_4_3 = size
                    }
                } else if (ratio === _ratio_16_9) {
                    if (size.width > max_16_9.width) {
                        max_16_9 = size
                    }
                }
            }
            if (supportedWideResolution.width !== max_4_3.width &&
                supportedWideResolution.height !== max_4_3.height) {
                supportedWideResolution = Qt.size(max_4_3.width, max_4_3.height)
            }
            if (supportedNarrowResolution.width !== max_16_9.width &&
                supportedNarrowResolution.height !== max_16_9.height) {
                supportedNarrowResolution = Qt.size(max_16_9.width, max_16_9.height)
            }
        }
    }

    Timer {
        id: reloadTimer
        interval: 100
    }

    // Display focus areas
    Repeater {
        model: camera.focus.focusZones
        delegate: Rectangle {
            visible: viewFinder.showFocusArea &&
                     status !== Camera.FocusAreaUnused &&
                     camera.focus.focusPointMode === Camera.FocusPointCustom &&
                     camera.cameraStatus === Camera.ActiveStatus
            border {
                width: Math.round(Theme.pixelRatio * 2)
                color: status === Camera.FocusAreaFocused ? Theme.highlightColor : "white"
            }
            color: "transparent"

            readonly property rect mappedRect: frameToViewfinderRect(area)
            readonly property real diameter: Math.round(Math.min(mappedRect.width, mappedRect.height))

            x: Math.round(mappedRect.x + (mappedRect.width - diameter)/2)
            y: Math.round(mappedRect.y + (mappedRect.height - diameter)/2)
            width: diameter
            height: diameter
            radius: diameter / 2
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: {
            focusTimer.restart()
            camera.unlock()
            camera.focus.customFocusPoint = viewfinderToFramePoint(mouse.x, mouse.y)
            camera.searchAndLock()
        }
    }

    Timer {
        id: focusTimer

        interval: 5000
        onTriggered: camera.unlock()
    }
}
