
import gamescene.GameScene;

class Game extends hxd.App {

    var currentScene: common.Scene;

    override function init() {
        // resize window if necessary
        var window = hxd.Window.getInstance();
        trace(window.width, window.height);
        Constants.windowWidth = window.width;
        Constants.windowHeight = window.height;
        Constants.globalScale = window.width / 800;
        // window.resize(1600, 900);

        hxd.Res.initEmbed();

        var assetsMap = common.Assets.parseAssets("assets.json");
        this.currentScene = new GameScene(assetsMap);

        // add event handler
        hxd.Window.getInstance().addEventTarget(onEvent);

    }

    override function update(dt:Float) {
        this.currentScene.update(dt);
    }

    override function render(engine: h3d.Engine) {
        this.currentScene.render(engine);
        this.s2d.render(engine);
    }

    function onEvent(event: hxd.Event) {
        this.currentScene.onEvent(event);
    }

}
