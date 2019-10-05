
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
    var camera: h2d.Camera;
    var backgroundLayer: h2d.Layers;
    var worldLayer: h2d.Layers;
    var foregroundLayer: h2d.Layers;

    var updater: Updater;

    var world: World;

    var timeElapsed: Float = 0;
    var timePerStep: Float = 0.1;

    var speciesList: Array<Species>;

    var moveCamera: Array<Bool> = [ false, false, false, false ];

    public function new(assets: common.Assets) {
        this.scene = new h2d.Scene();
        this.camera = new h2d.Camera(this.scene);
        this.assets = assets;
        this.init();
        this.updater = new Updater();
        this.speciesList = new Array<Species>();

        var species = new Species.PlantSpecies(assets);
        this.speciesList.push(species);

    }

    function init() {
        this.backgroundLayer = new h2d.Layers(this.camera);
        this.worldLayer = new h2d.Layers(this.camera);
        this.foregroundLayer = new h2d.Layers(this.camera);

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
        var camMove = new Point2f(0, 0);
        if (moveCamera[0]) camMove.y += dt * 500;
        if (moveCamera[1]) camMove.x -= dt * 500;
        if (moveCamera[2]) camMove.y -= dt * 500;
        if (moveCamera[3]) camMove.x += dt * 500;
        if (camMove.x != 0 || camMove.y != 0) {
            this.camera.x += camMove.x;
            this.camera.y += camMove.y;
            alignCamera();
        }
    }

    public function render(engine: h3d.Engine) {
        this.scene.render(engine);
    }

    public function onEvent(event: hxd.Event) {
        switch(event.kind) {
            case hxd.Event.EventKind.ERelease:
                this.mouseClicked(event);
            case hxd.Event.EventKind.EKeyDown:
                this.keyPressed(event);
            case hxd.Event.EventKind.EKeyUp:
                this.keyReleased(event);
            case hxd.Event.EventKind.EWheel:
                this.scroll(event);
            default:
        }
    }

    function scroll(event: hxd.Event) {
        if (event.wheelDelta > 0) {
            this.camera.scaleX -= Math.min(0.1, event.wheelDelta*0.01);
            this.camera.scaleY -= Math.min(0.1, event.wheelDelta*0.01);
        } else if (event.wheelDelta < 0) {
            this.camera.scaleX -= Math.max(-0.1, event.wheelDelta*0.01);
            this.camera.scaleY -= Math.max(-0.1, event.wheelDelta*0.01);
        }
        this.camera.scaleX = hxd.Math.clamp(this.camera.scaleX, 0.5, 1.5);
        this.camera.scaleY = hxd.Math.clamp(this.camera.scaleY, 0.5, 1.5);
        this.alignCamera();
    }

    function alignCamera() {
        var window = hxd.Window.getInstance();
        this.camera.x = hxd.Math.clamp(
                this.camera.x,
                -(Constants.GridSize*this.camera.scaleX)*Constants.WorldWidth-5+window.width,
                5);
        this.camera.y = hxd.Math.clamp(
                this.camera.y,
                -(Constants.GridSize*this.camera.scaleY)*Constants.WorldHeight-5+window.height,
                5);
    }

    function keyPressed(event: hxd.Event) {
        switch(event.keyCode) {
            case hxd.Key.W:
                this.moveCamera[0] = true;
            case hxd.Key.D:
                this.moveCamera[1] = true;
            case hxd.Key.S:
                this.moveCamera[2] = true;
            case hxd.Key.A:
                this.moveCamera[3] = true;
            default:
        }
    }

    function keyReleased(event: hxd.Event) {
        switch(event.keyCode) {
            case hxd.Key.W:
                this.moveCamera[0] = false;
            case hxd.Key.D:
                this.moveCamera[1] = false;
            case hxd.Key.S:
                this.moveCamera[2] = false;
            case hxd.Key.A:
                this.moveCamera[3] = false;
            default:
        }
    }

    function mouseClicked(event: hxd.Event) {
        // check state
        var pos = translateWorldPosToCell(translateMousePositionToWorld([event.relX, event.relY]));
        if (!this.world.inBound(pos)) return;
        if (this.world.cells[pos.x][pos.y].plant != null) return;

        this.placeLife(pos);
    }

    function placeLife(pos: Point2i) {
        var life = this.speciesList[0].newLife();
        this.world.moveLife(life, pos);
    }

    function translateMousePositionToWorld(pos: Point2f): Point2f {
        pos = pos - [this.camera.x, this.camera.y];
        return pos;
    }

    function translateWorldPosToCell(pos: Point2f): Point2i {
        return [
            Math.floor(pos.x / (Constants.GridSize*this.camera.scaleX)),
            Math.floor(pos.y / (Constants.GridSize*this.camera.scaleY))
        ];
    }
}
