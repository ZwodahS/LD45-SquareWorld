
package gamescene;

import haxe.ds.Vector;
import haxe.ds.List;
import common.Point2i;
import common.Point2f;

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


class GameScene implements common.Scene {


    var assets: common.Assets;

    var scene: h2d.Scene;
    var backgroundLayer: h2d.Layers;
    var worldLayer: h2d.Layers;
    var foregroundLayer: h2d.Layers;

    var updater: Updater;

    var world: World;

    var timeElapsed: Float = 0;
    var timePerStep: Float = 0.1;

    var speciesList: Array<Species>;

    public function new(assets: common.Assets) {
        this.scene = new h2d.Scene();
        this.assets = assets;
        this.init();
        this.updater = new Updater();
        this.speciesList = new Array<Species>();

        var species = new Species.PlantSpecies(assets);
        this.speciesList.push(species);

    }

    function init() {
        this.backgroundLayer = new h2d.Layers(this.scene);
        this.worldLayer = new h2d.Layers(this.scene);
        this.foregroundLayer = new h2d.Layers(this.scene);

        this.world = new World(this.worldLayer, Constants.WorldWidth, Constants.WorldHeight);
        for (x in 0...Constants.WorldWidth) {
            for (y in 0...Constants.WorldHeight) {
                this.worldLayer.add(this.world.cells[x][y].drawable, 0);
            }
        }
    }

    public function update(dt: Float) {
        updater.update(dt);

        this.timeElapsed += dt;
        if (timeElapsed > this.timePerStep) {
            this.timeElapsed -= this.timePerStep;

            for (life in this.world.lifeList) {
                life.processMove(this.world);
            }
            for (life in this.world.lifeList) {
                life.processExtract(this.world);
            }
            for (life in this.world.lifeList) {
                life.processProduce(this.world);
            }
            for (life in this.world.lifeList) {
                life.processAge(this.world);
            }
            for (life in this.world.lifeList) {
                if (!life.isAlive) {
                    life.processDie(this.world);
                    this.world.removeLife(life);
                }
            }
            for (life in this.world.lifeList) {
                life.processReproduce(this.world);
            }
        }
    }

    public function render(engine: h3d.Engine) {
        this.scene.render(engine);
    }

    public function onEvent(event: hxd.Event) {
        switch(event.kind) {
            case hxd.Event.EventKind.ERelease:
                this.mouseClicked(event);
            default:
        }
    }

    function mouseClicked(event: hxd.Event) {
        // check state
        var pos = translateWorldPosToCell(translateMousePositionToWorld([
                    event.relX, event.relY
        ]));
        if (!this.world.inBound(pos)) {
            return;
        }
        if (this.world.cells[pos.x][pos.y].plant != null) {
            return;
        }
        this.placeLife(pos);
    }

    function placeLife(pos: Point2i) {
        var life = this.speciesList[0].newLife();
        this.world.moveLife(life, pos);
    }

    function translateMousePositionToWorld(pos: Point2f): Point2f {
        return pos;
    }

    function translateWorldPosToCell(pos: Point2f): Point2i {
        return [Math.floor(pos.x / Constants.GridSize), Math.floor(pos.y / Constants.GridSize) ];
    }
}
