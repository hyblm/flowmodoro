import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class FlowView extends WatchUi.View {
    private var _primary = "FOCUS";
    private var _secondary = "";
    private var _select = "start";
    private var _back = "";
    private var _next = "";
    private var _progress = null;
    private var _status = "";
    private var _visible = false;
    private var _animation;
    private var _animating = false;
    private var _startedAt = 0;
    private var _controls = 1.0;
    private var _controlsFrom = 1.0;
    private var _controlsTo = 1.0;
    private var _phaseMotion = false;

    function initialize() {
        View.initialize();
        _animation = new Timer.Timer();
    }

    // One atomic presentation update prevents several setters restarting animation.
    function present(primary, secondary, selectLabel, backLabel, nextLabel, progress, status) as Void {
        var controlsTo = selectLabel.equals("") ? 0.0 : 1.0;
        var startingFocus = _select.equals("start") && selectLabel.equals("pause");
        var phaseChanged = startingFocus || !_primary.equals(primary) || !_status.equals(status);
        var controlsChanged = controlsTo != _controlsTo;
        _primary = primary;
        _secondary = secondary;
        _progress = progress;
        _status = status;
        // Retain outgoing labels until they have faded out.
        if (!selectLabel.equals("")) { _select = selectLabel; }
        if (!backLabel.equals("") || controlsTo > 0) { _back = backLabel; }
        if (!nextLabel.equals("") || controlsTo > 0) { _next = nextLabel; }
        if (phaseChanged || controlsChanged) {
            _controlsFrom = _controls;
            _controlsTo = controlsTo;
            _phaseMotion = phaseChanged;
            _startedAt = System.getTimer();
            if (_visible) {
                _animating = true;
                _animation.stop();
                _animation.start(method(:animate), 50, true);
            } else {
                _controls = _controlsTo;
            }
        }
        if (_visible) { WatchUi.requestUpdate(); }
    }

    function onShow() as Void {
        _visible = true;
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        _visible = false;
        _animation.stop();
        _animating = false;
        _controls = _controlsTo;
    }

    function refresh() as Void {
        if (_visible) { WatchUi.requestUpdate(); }
    }

    function animate() as Void {
        if (!_visible) { return; }
        if (System.getTimer() - _startedAt >= 250) {
            _animation.stop();
            _animating = false;
            _controls = _controlsTo;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        var accent = _primary.equals("BREAK") ? 0x55DDAA : 0xAAAAFF;
        var ease = 1.0;
        if (_animating) {
            var t = (System.getTimer() - _startedAt) / 250.0;
            if (t > 1.0) { t = 1.0; }
            // Cubic ease-out; duration is wall-clock based, not callback-count based.
            ease = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
            _controls = _controlsFrom + (_controlsTo - _controlsFrom) * ease;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

        if (_progress != null) {
            var radius = ((width < height) ? width : height) / 2 - 5;
            dc.setPenWidth(3);
            dc.setColor(0x222222, Graphics.COLOR_BLACK);
            dc.drawCircle(centerX, centerY, radius);
            dc.setColor(accent, Graphics.COLOR_BLACK);
            if (_progress >= 1.0) {
                dc.drawCircle(centerX, centerY, radius);
            } else if (_progress > 0) {
                dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, 90, 90 - 360 * _progress);
            }
            dc.setPenWidth(1);
        }

        var offset = (_phaseMotion && _animating) ? ((1.0 - ease) * 8).toNumber() : 0;
        dc.setColor(accent, Graphics.COLOR_BLACK);
        dc.drawText(centerX, (height * 0.33).toNumber() + offset, Graphics.FONT_SMALL, _primary, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var timerFont = _select.equals("start") ? Graphics.FONT_SMALL : Graphics.FONT_NUMBER_MEDIUM;
        dc.drawText(centerX, (height * 0.46).toNumber() + offset, timerFont, _secondary, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0xAAAAAA, Graphics.COLOR_BLACK);
        dc.drawText(centerX, (height * 0.79).toNumber(), Graphics.FONT_XTINY, _status, Graphics.TEXT_JUSTIFY_CENTER);

        if (_controls > 0.01) {
            // Grayscale steps work on the FR955's MIP display; no alpha blending.
            var shade = (170 * _controls).toNumber();
            dc.setColor(shade * 0x010101, Graphics.COLOR_BLACK);
            var slide = ((1.0 - _controls) * 8).toNumber();
            dc.drawText((width * 0.87).toNumber() + slide, (height * 0.18).toNumber(), Graphics.FONT_XTINY, _select, Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText((width * 0.87).toNumber() + slide, (height * 0.68).toNumber(), Graphics.FONT_XTINY, _back, Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText((width * 0.13).toNumber() - slide, (height * 0.68).toNumber(), Graphics.FONT_XTINY, _next, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
}
