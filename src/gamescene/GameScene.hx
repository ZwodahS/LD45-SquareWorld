
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


class Hud {

    public var drawable: h2d.Layers;

    public var speciesList: Array<Species>;

    var speciesDrawable: Array<Species.SpCard>;

    public function new(assets: common.Assets) {
        this.drawable = new h2d.Layers();
        this.drawable.scaleX = Constants.globalScale;
        this.drawable.scaleY = Constants.globalScale;

        var hudBG = assets.getAsset("background").tiles[0].getBitmap();
        this.drawable.add(hudBG, 0);
        this.drawable.x = Constants.windowWidth - (160 * Constants.globalScale);
        this.speciesList = new Array<Species>();
        this.speciesDrawable = new Array<Species.SpCard>();
    }

    public function addSpecies(species: Species) {
        if (this.speciesList.indexOf(species) != -1) {
            return;
        }
        this.speciesList.push(species);
        this.speciesDrawable.push(species.drawable);
        this.drawable.add(species.drawable, 0);
        this.redraw();
    }

    public function redraw() {
        var ind = 0;
        for (d in this.speciesDrawable) {
            d.x = 10;
            d.y = 180 + (ind * 60);
            ind++;
        }
    }

    var currentSelect: Int = -1;
    var currentHover: Int = -1;

    public function selectedSpecies(): Species {
        if (this.currentSelect == -1) return null;

        return speciesList[this.currentSelect];
    }

    public function mouseMoved(event: hxd.Event) {
        var newHover = this.findSelectedInd(new h2d.col.Point(event.relX, event.relY));

        if (newHover == currentHover) return;

        if (currentHover != -1) {
            this.speciesDrawable[currentHover].unhover();
        }

        currentHover = newHover;

        if (currentHover == -1) return;

        this.speciesDrawable[currentHover].hover();
    }

    public function mouseClicked(event: hxd.Event) {
        if (event.button == 0) {
            var card = this.findSelectedInd(new h2d.col.Point(event.relX, event.relY));
            if (card == -1) {
            } else {
                this.selectSpecies(card);
            }
        }
    }

    function findSelectedInd(point: h2d.col.Point): Int {
        var newHover = -1;
        var ind = 0;
        for (item in this.speciesDrawable) {
            if (item.getBounds().contains(point)) {
                newHover = ind;
                break;
            }
            ind++;
        }
        return newHover;
    }

    public function selectSpecies(i: Int) {
        if (i >= 0 && i < this.speciesList.length) {
            this._selectSpecies(i);
        }
    }

    function _selectSpecies(i: Int) {
        if (currentSelect != -1) this.speciesDrawable[currentSelect].unselect();
        if (i == this.currentSelect) {
            currentSelect = -1;
        } else {
            currentSelect = i;
            this.speciesDrawable[currentSelect].select();
        }
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

    var hud: Hud;
    var isPaused: Bool = false;

    public function new(assets: common.Assets) {
        this.scene = new h2d.Scene();
        this.camera = new h2d.Camera(this.scene);
        this.assets = assets;
        this.init();
        this.updater = new Updater();
        this.speciesList = new Array<Species>();
        this.hud = new Hud(assets);
        this.scene.add(this.hud.drawable, 0);

        this.speciesList.push(new Species.PlantSpecies(assets));
        this.speciesList.push(new Species.AnimalSpecies(assets));
        this.speciesList.push(new Species.AnimalSpecies(assets));
        this.speciesList.push(new Species.AnimalSpecies(assets));
        this.speciesList.push(new Species.AnimalSpecies(assets));
        this.speciesList.push(new Species.AnimalSpecies(assets));
        this.speciesList.push(new Species.AnimalSpecies(assets));
        this.speciesList.push(new Species.AnimalSpecies(assets));

        for (s in this.speciesList) {
            this.hud.addSpecies(s);
        }

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

    function simulate() {
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

    public function update(dt: Float) {
        updater.update(dt);

        this.timeElapsed += dt;
        if (timeElapsed > this.timePerStep) {
            this.timeElapsed -= this.timePerStep;
            if (!this.isPaused) {
                this.simulate();
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
            case hxd.Event.EventKind.EPush:
                this.mouseDown(event);
            case hxd.Event.EventKind.ERelease:
                this.mouseUp(event);
            case hxd.Event.EventKind.EMove:
                this.mouseMoved(event);
            case hxd.Event.EventKind.EKeyDown:
                this.keyPressed(event);
            case hxd.Event.EventKind.EKeyUp:
                this.keyReleased(event);
            case hxd.Event.EventKind.EWheel:
                this.scroll(event);
            default:
        }
    }

    var mouseDownEvent: hxd.Event = null;
    var startDrag: Bool = false;
    function mouseDown(event: hxd.Event) {
        this.mouseDownEvent = event;
    }

    function mouseMoved(event: hxd.Event) {
        this.hud.mouseMoved(event);
        if (this.mouseDownEvent != null) {
            if (this.startDrag == false) {
                var diff = (
                        Math.abs(event.relX - this.mouseDownEvent.relX) +
                        Math.abs(event.relY - this.mouseDownEvent.relY)
                );
                if (diff > 20) {
                    this.startDrag = true;
                }
            }

            if (this.startDrag) {
                var diff = new Point2f(
                    event.relX - this.mouseDownEvent.relX,
                    event.relY - this.mouseDownEvent.relY
                );
                this.drag(diff);
                this.mouseDownEvent.relX = event.relX;
                this.mouseDownEvent.relY = event.relY;
            }
        }
    }

    function drag(diff: Point2f) {
        this.camera.x += diff.x;
        this.camera.y += diff.y;
        alignCamera();
    }

    function mouseUp(event: hxd.Event) {
        this.mouseDownEvent = null;
        if (this.startDrag) {
            this.startDrag = false;
            return;
        }
        if (event.relX > ((800 - 160) * Constants.globalScale)) {
            this.hud.mouseClicked(event);
        } else {
            // check state
            if (event.button == 0) {
                var pos = translateWorldPosToCell(translateMousePositionToWorld([event.relX, event.relY]));
                if (!this.world.inBound(pos)) return;
                if (this.world.cells[pos.x][pos.y].plant != null) return;
                this.placeLife(pos);
            }
        }
    }

    function scroll(event: hxd.Event) {
        if (event.wheelDelta > 0) {
            this.camera.scaleX -= Math.min(0.1, event.wheelDelta*0.01) * Constants.globalScale;
            this.camera.scaleY -= Math.min(0.1, event.wheelDelta*0.01) * Constants.globalScale;
        } else if (event.wheelDelta < 0) {
            this.camera.scaleX -= Math.max(-0.1, event.wheelDelta*0.01) * Constants.globalScale;
            this.camera.scaleY -= Math.max(-0.1, event.wheelDelta*0.01) * Constants.globalScale;
        }
        this.camera.scaleX = hxd.Math.clamp(this.camera.scaleX, Constants.globalScale*0.5, Constants.globalScale*1.5);
        this.camera.scaleY = hxd.Math.clamp(this.camera.scaleY, Constants.globalScale*0.5, Constants.globalScale*1.5);
        this.alignCamera();
    }

    function alignCamera() {
        var window = hxd.Window.getInstance();
        this.camera.x = hxd.Math.clamp(
                this.camera.x,
                -(Constants.GridSize*this.camera.scaleX)*Constants.WorldWidth-5+window.width-160,
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
            case hxd.Key.SPACE:
                this.isPaused = !this.isPaused;
            case hxd.Key.ESCAPE:
                this.hud.selectSpecies(-1);
            case hxd.Key.NUMBER_1:
                this.hud.selectSpecies(0);
            case hxd.Key.NUMBER_2:
                this.hud.selectSpecies(1);
            case hxd.Key.NUMBER_3:
                this.hud.selectSpecies(2);
            case hxd.Key.NUMBER_4:
                this.hud.selectSpecies(3);
            case hxd.Key.NUMBER_5:
                this.hud.selectSpecies(4);
            case hxd.Key.NUMBER_6:
                this.hud.selectSpecies(5);
            case hxd.Key.NUMBER_7:
                this.hud.selectSpecies(6);
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

    function placeLife(pos: Point2i) {
        var sp = this.hud.selectedSpecies();
        if (sp == null) return;

        var life = sp.newLife();
        life.x = pos.x;
        life.y = pos.y;
        this.world.addLife(life);
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
