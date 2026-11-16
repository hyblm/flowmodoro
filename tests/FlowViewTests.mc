import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;

(:test)
function flowViewRendering(logger as Test.Logger) as Boolean {
    var bitmap = Graphics.createBufferedBitmap({ :width => 260, :height => 260 });
    var dc = (bitmap.get() as Graphics.BufferedBitmap).getDc();
    var view = new FlowView();
    view.onUpdate(dc);
    view.onShow();
    view.present("FOCUS", "12:34", "pause", "exit", "break", null, "");
    view.onUpdate(dc);
    view.present("FOCUS", "", "", "", "", null, "");
    view.onUpdate(dc);
    view.onHide();
    view.onUpdate(dc);
    view.present("FOCUS", "12:34", "resume", "exit", "break", null, "Paused");
    view.onUpdate(dc);
    view.present("BREAK", "3:00", "focus", "exit", "", 0.0, "");
    view.onUpdate(dc);
    view.present("BREAK", "1:30", "focus", "exit", "", 0.5, "");
    view.onUpdate(dc);
    view.present("BREAK", "+1:30", "focus", "exit", "", 1.0, "");
    view.onUpdate(dc);
    return true;
}
