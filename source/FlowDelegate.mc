import Toybox.Lang;
import Toybox.WatchUi;

class FlowDelegate extends WatchUi.BehaviorDelegate {

    private var _timer;
    private var _focusStartedAt;
    private var _pausedAt;
    private var _breakTargetAt = 0;
    private var _breakTargetSeconds = 0;
    private var _breakNotified = false;
    private var _hoverSecondsRemaining = 0;
    private var _view = getView();
    private var _state = TimerState.Initial;

    function initialize() {
        BehaviorDelegate.initialize();
        _timer = new Timer.Timer();
    }

    function onSelect() as Boolean {
        switch (_state) {
            case TimerState.Initial:
                startFocus();
                break;
            case TimerState.Focus:
                showFocusControls();
                break;
            case TimerState.FocusHover:
                pauseFocus();
                break;
            case TimerState.FocusPaused:
                resumeFocus();
                break;
            case TimerState.BreakHover:
                startFocus();
                break;
        }
        return true;
    }

    function onBack() as Boolean {
        if (_state != TimerState.Focus) {
            System.exit();
        }
        return true;
    }

    function onNextPage() as Boolean {
        switch (_state) {
            case TimerState.FocusHover:
            case TimerState.FocusPaused:
                startBreak();
                break;
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new FlowMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function startFocus() as Void {
        _timer.stop();
        _focusStartedAt = Toybox.Time.now();
        showFocusControls();
    }

    function showFocusControls() as Void {
        _state = TimerState.FocusHover;
        _hoverSecondsRemaining = 5;
        _timer.start(method(:tickFocusHover), 1000, true);
        updateViewForState();
    }

    function pauseFocus() as Void {
        _timer.stop();
        _pausedAt = Toybox.Time.now();
        _state = TimerState.FocusPaused;
        updateViewForState();
    }

    function resumeFocus() as Void {
        var pauseDuration = Toybox.Time.now().subtract(_pausedAt);
        _focusStartedAt = _focusStartedAt.add(pauseDuration);
        _state = TimerState.Focus;
        updateViewForState();
    }

    function startBreak() as Void {
        _timer.stop();
        var focusEnd = (_state == TimerState.FocusPaused) ? _pausedAt : Toybox.Time.now();
        var targetSeconds = focusEnd.subtract(_focusStartedAt).value() / 4;
        var now = Toybox.Time.now().value();
        _breakTargetSeconds = targetSeconds;
        _breakTargetAt = now + targetSeconds;
        _breakNotified = false;
        _state = TimerState.BreakHover;
        _timer.start(method(:tickBreak), 1000, true);
        tickBreak();
    }

    function tickFocusHover() as Void {
        _hoverSecondsRemaining--;
        if (_hoverSecondsRemaining <= 0) {
            _timer.stop();
            _state = TimerState.Focus;
        }
        updateViewForState();
    }

    function tickBreak() as Void {
        if (!_breakNotified && Toybox.Time.now().value() >= _breakTargetAt) {
            _breakNotified = true;
            if (Attention has :vibrate) {
                vibrateBreakTarget();
            }
        }
        updateViewForState();
    }

    function vibrateBreakTarget() as Void {
        Attention.vibrate([
            new Attention.VibeProfile(40, 100),
            new Attention.VibeProfile(0, 40),
            new Attention.VibeProfile(50, 100),
        ]);
    }

    function updateViewForState() as Void {
        var primary = "FOCUS";
        var secondary = "";
        var selectLabel = "";
        var backLabel = "";
        var nextLabel = "";
        var progress = null;
        var status = "";

        switch (_state) {
            case TimerState.Initial:
                selectLabel = "start";
                break;
            case TimerState.FocusHover:
            case TimerState.FocusPaused:
                var focusEnd = (_state == TimerState.FocusPaused) ? _pausedAt : Toybox.Time.now();
                secondary = format_timer(focusEnd.subtract(_focusStartedAt).value());
                selectLabel = (_state == TimerState.FocusPaused) ? "resume" : "pause";
                if (_state == TimerState.FocusPaused) { status = "Paused"; }
                backLabel = "exit";
                nextLabel = "break";
                break;
            case TimerState.BreakHover:
                primary = "BREAK";
                var remaining = _breakTargetAt - Toybox.Time.now().value();
                secondary = (remaining < 0) ? "+" + format_timer(-remaining) : format_timer(remaining);
                selectLabel = "focus";
                backLabel = "exit";
                progress = (_breakTargetSeconds > 0) ? 1.0 - remaining.toFloat() / _breakTargetSeconds : 1.0;
                if (progress > 1.0) { progress = 1.0; }
                if (progress < 0.0) { progress = 0.0; }
                break;
        }

        _view.present(primary, secondary, selectLabel, backLabel, nextLabel, progress, status);
    }
}

function format_timer(total_seconds as Toybox.Lang.Number) as Toybox.Lang.String {
    var hours = total_seconds / 3600;
    var minutes = (total_seconds % 3600) / 60;
    var seconds = total_seconds % 60;
    var text;
    if (hours > 0) {
        var minutesTwoDigits = (minutes > 9) ? minutes.toString() : "0" + minutes.toString();
        text = hours.toString() + ":" + minutesTwoDigits + ":";
    } else {
        text = minutes.toString() + ":";
    }
    var secondsTwoDigits = (seconds > 9) ? seconds.toString() : "0" + seconds.toString();
    return text + secondsTwoDigits;
}
