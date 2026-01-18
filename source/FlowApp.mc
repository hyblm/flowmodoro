import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FlowApp extends Application.AppBase {
    private var _view;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        _view =  new FlowView();
        return [_view, new FlowDelegate() ];
    }

    function getView() {
        return _view;
    }

}

function getApp() as FlowApp {
    return Application.getApp() as FlowApp;
}

function getView() as FlowView {
    return Application.getApp().getView() as FlowView;
}