import Toybox.Graphics;
import Toybox.WatchUi;

class FlowView extends WatchUi.View {
    private var _primary;
    private var _secondary;

    private var _btn_select;
    private var _btn_back;
    private var _btn_next;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));

        _primary = findDrawableById("primary");
        _secondary = findDrawableById("secondary");
        _btn_select = findDrawableById("btn_select");
        _btn_back = findDrawableById("btn_back");
        _btn_next = findDrawableById("btn_next");
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    function set_primary_label(text) as Void {
        _primary.setText(text);
    }

    function set_secondary_label(text) as Void {
        _secondary.setText(text);
    }

    function set_btn_select(text) as Void {
        _btn_select.setText(text);
    }

    function set_btn_back(text) as Void {
        _btn_back.setText(text);
    }

    function set_btn_next(text) as Void {
        _btn_next.setText(text);
    }
}