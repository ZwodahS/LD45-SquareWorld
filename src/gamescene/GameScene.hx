
package gamescene;

import haxe.ds.Vector;
import gamescene.Life;

interface Updatable {
    function update(dt: Float): Void ;
    function isDone(): Bool;
}

class Updater {
    var updates: List<Updatable>;

    public function new() {
        this.updates = new List<Updatable>();
    }

    public function update(dt: Float) {
        for (u in updates) {
            u.update(dt);
        }

        this.updates = updates.filter(function(u: Updatable): Bool {
            return u.isDone();
        });
    }
}

class Grid {

    public var drawable: h2d.Layers;
    public var x(default, set): Int;
    public var y(default, set): Int;

    var nutrientsBitmap: h2d.Bitmap;

    public var nutrients: Int;

    public function new() {
        this.drawable = new h2d.Layers();
        this.drawable.add(new h2d.Bitmap(h2d.Tile.fromColor(0x241C07, Constants.GridSize, Constants.GridSize)), 0);
        this.nutrientsBitmap = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFF55, Constants.GridSize, Constants.GridSize));
        this.drawable.add(nutrientsBitmap, 1);
        this.nutrients = Math.floor(Math.random() * 10);
        this.nutrientsBitmap.color.w = Math.min(this.nutrients / 300, 0.3);
    }

    public function set_x(x: Int): Int {
        this.x = x;
        this.drawable.x = x * Constants.GridSize;
        return this.x;
    }

    public function set_y(y: Int): Int {
        this.y = y;
        this.drawable.y = y * Constants.GridSize;
        return this.y;
    }
}



class GameScene implements common.Scene {


    var assets: common.Assets;

    var scene: h2d.Scene;
    var backgroundLayer: h2d.Layers;
    var worldLayer: h2d.Layers;
    var foregroundLayer: h2d.Layers;

    var updater: Updater;

    var world: Vector<Vector<Grid>>;

    public function new(assets: common.Assets) {
        this.scene = new h2d.Scene();
        this.assets = assets;
        this.init();
        this.updater = new Updater();

        var species = new Species(assets);

        var creature = species.newLife();
        this.worldLayer.add(creature.drawable, 0);
    }

    function init() {
        this.backgroundLayer = new h2d.Layers(this.scene);
        this.worldLayer = new h2d.Layers(this.scene);
        this.foregroundLayer = new h2d.Layers(this.scene);

        this.world = new Vector<Vector<Grid>>(Constants.WorldWidth);
        for (x in 0...Constants.WorldWidth) {
            this.world[x] = new Vector<Grid>(Constants.WorldHeight);
            for (y in 0...Constants.WorldHeight) {
                var grid = new Grid();
                grid.x = x;
                grid.y = y;
                this.world[x][y] = grid;
                this.backgroundLayer.add(grid.drawable, 0);
            }
        }
    }

    public function update(dt: Float) {
        updater.update(dt);
    }

    public function render(engine: h3d.Engine) {
        this.scene.render(engine);
    }

    public function onEvent(event: hxd.Event) {
    }

}
