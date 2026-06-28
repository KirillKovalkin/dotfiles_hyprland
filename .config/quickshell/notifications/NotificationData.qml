import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: notificationData

    property Notification notification: null
    property bool closed: false
    property bool _destroyed: false

    property string seqId: ""
    property string notifId: ""

    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property string appName: ""
    property string image: ""
    property var    actions: []
    property int    urgency: NotificationUrgency.Normal
    property real   expireTimeout: defaultTimeout

    property bool hovered: false

    readonly property int defaultTimeout: 5000  // ms — fallback auto-dismiss when app sends -1/0

    readonly property Connections _conn: Connections {
        target: notificationData.notification

        function onClosed(): void {
            if (notificationData.closed) return;
            notificationData.closed = true;
            NotificationService._remove(notificationData);
            notificationData.destroy();
        }

        function onSummaryChanged(): void {
            if (notificationData.notification) notificationData.summary = notificationData.notification.summary || "";
        }
        function onBodyChanged(): void {
            if (notificationData.notification) notificationData.body = notificationData.notification.body || "";
        }
        function onAppIconChanged(): void {
            if (notificationData.notification) notificationData.appIcon = notificationData.notification.appIcon || "";
        }
        function onAppNameChanged(): void {
            if (notificationData.notification) notificationData.appName = notificationData.notification.appName || "";
        }
        function onImageChanged(): void {
            if (notificationData.notification) notificationData.image = notificationData.notification.image || "";
        }
        function onUrgencyChanged(): void {
            if (notificationData.notification) notificationData.urgency = notificationData.notification.urgency;
        }
        function onExpireTimeoutChanged(): void {
            if (notificationData.notification) notificationData.expireTimeout = notificationData.notification.expireTimeout;
        }
        function onActionsChanged(): void {
            if (!notificationData.notification) return;
            notificationData.actions = notificationData.notification.actions.map(function(a) {
                return { identifier: a.identifier, text: a.text };
            });
        }
    }

    readonly property Timer _timer: Timer {
        running: !notificationData.closed
                 && !notificationData.hovered
                 && notificationData.urgency !== NotificationUrgency.Critical
        interval: notificationData.expireTimeout > 0 ? notificationData.expireTimeout : notificationData.defaultTimeout  // no * 1000: Quickshell passes raw D-Bus ms, not seconds
        onTriggered: {
            notificationData.dismiss()
        }
    }

    Component.onCompleted: {
        if (!notification) return;
        notifId   = String(notification.id || "");
        summary   = notification.summary   || "";
        body      = notification.body      || "";
        appIcon   = notification.appIcon   || "";
        appName   = notification.appName   || "";
        image     = notification.image     || "";
        urgency   = notification.urgency;

        const rawTimeout = notification.expireTimeout;
        expireTimeout = rawTimeout > 0 ? rawTimeout : defaultTimeout;
        actions   = notification.actions.map(function(a) {
            return { identifier: a.identifier, text: a.text };
        });
    }

    function dismiss(): void {
        if (closed || _destroyed) return;
        closed = true;
        NotificationService._remove(notificationData);
        if (notification) try { notification.dismiss(); } catch(e) {}
        _cleanupAndDestroy();
    }

    function invokeAction(identifier): void {
        if (!identifier || closed || _destroyed) return;
        closed = true;
        NotificationService._remove(notificationData);
        if (notification) {
            const action = notification.actions.find(function(a) {
                return a.identifier === identifier;
            });
            if (action) try { action.invoke(); } catch(e) {}
        }
        _cleanupAndDestroy();
    }

    function _cleanupAndDestroy(): void {
        if (_destroyed) return;
        _destroyed = true;
        _timer.stop();
        // Detach Connections target to release the notification reference
        _conn.target = null;
        destroy();
    }

    Component.onDestruction: {
        // Safety net: ensure cleanup even if dismiss() wasn't called explicitly
        if (!_destroyed) {
            _destroyed = true;
            _timer.stop();
            _conn.target = null;
        }
    }
}
