import Toybox.Lang;
import Toybox.WatchUi;

class FlowDelegate extends WatchUi.BehaviorDelegate {

    private var _timer;
    private var _timer_value;
    private var _time = 0;
    private var _time2 = 0;
    private var _view = getView();
    private var _state = TimerState.Initial;

    function initialize() {
        BehaviorDelegate.initialize();
        _timer = new Timer.Timer(); 
    }

    function onSelect() as Boolean {
        switch (_state) {
            case TimerState.Initial: 
                Attention.vibrate([]);
                _time = Toybox.Time.now();

            case TimerState.Focus:
                _state = TimerState.FocusHover;
                _view.set_btn_select("pause");
                _view.set_btn_back("exit");
                _view.set_btn_next("break");
                var focus_time = (Toybox.Time.now().subtract(_time)).value();
                _view.set_secondary_label(format_timer(focus_time));
                _timer_value = 5;
                _timer.start(method(:unhover_focus), 1000, true);
                break;

            case TimerState.FocusHover:
                _state = TimerState.FocusPaused;
                _time2 = Toybox.Time.now();
                var duration = (_time2.subtract(_time)).value();
                _view.set_secondary_label(format_timer(duration));
                _view.set_btn_select("resume");
                _timer.stop();
                break;

            case TimerState.FocusPaused:
                _state = TimerState.Focus;
                var break_duration = (Toybox.Time.now().subtract(_time2));
                _time = _time.add(break_duration);
                _view.set_secondary_label("");
                _view.set_btn_back("");
                _view.set_btn_select("");
                _view.set_btn_next("");
                break;

            case TimerState.BreakHover:
                _view.set_btn_select("resume");
                _timer.stop();
                break;
            case TimerState.BreakPaused:
                _view.set_btn_select("pause");
               _timer.start(method(:tickDown), 1000, true);
                break;


        }
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        switch (_state) {
            case TimerState.Initial:
            case TimerState.FocusHover:
            case TimerState.FocusPaused:
            case TimerState.BreakHover:
            case TimerState.BreakPaused:
                System.exit();
            default:
                break;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function unhover_focus() as Void {
        if (_timer_value > 0) {
            _timer_value --;
            var focus_time = (Toybox.Time.now().subtract(_time)).value();
            _view.set_secondary_label(format_timer(focus_time));

        } else {
            _view.set_btn_select("");
            _view.set_btn_back("");
            _view.set_btn_next("");
            _view.set_secondary_label("");
            _state = TimerState.Focus;

            _timer.stop();
        }
        WatchUi.requestUpdate();
    }

    function onNextPage() as Boolean {
        System.println("next pressed");
        System.println(_state);
        switch (_state) {
            case TimerState.FocusHover:
            case TimerState.FocusPaused:
                _view.set_primary_label("BREAK");
                var duration = Toybox.Time.now().subtract(_time);
                var seconds = duration.value();
                _time = seconds / 4;
               _timer.start(method(:tickDown), 1000, true);
            case TimerState.Break:
                _state = TimerState.BreakHover; 
                _view.set_btn_select("pause");
                _view.set_btn_back("exit");
                _view.set_btn_next("focus");
                break;
            case TimerState.BreakHover:
            case TimerState.BreakPaused:
                Attention.vibrate([]);
                _state = TimerState.FocusHover;
                _time = Toybox.Time.now();
                _view.set_primary_label("FOCUS");
                _view.set_btn_select("pause");
                _view.set_btn_back("exit");
                _view.set_btn_next("break");
                var focus_time = (Toybox.Time.now().subtract(_time)).value();
                _view.set_secondary_label(format_timer(focus_time));
                _timer_value = 5;
                _timer.start(method(:unhover_focus), 1000, true);
                break;
            default:
                break;
        }


        return true;
    }

    function onPreviousPage() as Boolean {
        System.println("previous page");
        return true;

    }
    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new FlowMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function tickUp() {
        _time++;
        _view.set_secondary_label(format_timer(_time));
    }

    function tickDown() {
        if (_time) {
            _time--;
            _view.set_secondary_label(format_timer(_time));
            WatchUi.requestUpdate();
        } else {
            _timer.stop();
        _state = TimerState.Initial;
            _view.set_btn_select("start");
            _view.set_btn_back("");
            _view.set_btn_next("");
            _view.set_secondary_label("");
            _view.set_primary_label("FOCUS");
            WatchUi.requestUpdate();
            if (Attention has :vibrate) {
                var vibeData =
                [
                    new Attention.VibeProfile(50, 2000), // On for two seconds
                    new Attention.VibeProfile(0, 2000),  // Off for two seconds
                    new Attention.VibeProfile(50, 2000), // On for two seconds
                    new Attention.VibeProfile(0, 2000),  // Off for two seconds
                    new Attention.VibeProfile(50, 2000)  // on for two seconds
                ];
                Attention.vibrate(vibeData);
            }
        }
    }

}

function format_timer(total_seconds as Toybox.Lang.Number) as Toybox.Lang.String {
    var hours = total_seconds / (3600);
    var minutes = (total_seconds % (3600)) / 60;
    var seconds = total_seconds % 60;

    var updated_text;
        if (hours) {
        var minutes_two_digits = (minutes > 9) ? minutes.toString() : "0" + minutes.toString();
        updated_text = hours.toString() + ":" + minutes_two_digits;
        } else {
        updated_text =  minutes.toString() + ":";
        }

    var seconds_two_digits = (seconds > 9) ? seconds.toString() : "0" + seconds.toString();
    updated_text += seconds_two_digits;

    return updated_text;
}