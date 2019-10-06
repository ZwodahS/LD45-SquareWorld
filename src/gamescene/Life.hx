
package gamescene;

import haxe.ds.Vector;
import common.Direction;

class Life {

    var species: Species;

    public var age(default, set): Int = 0;
    public var drawable: h2d.Layers;

    public var x(default, set): Int = 0;
    public var y(default, set): Int = 0;

    public var energy: Int = 0;
    public var size: Float = 0.5;
    public var isAlive(get, null): Bool;

    public var type(get, null): String;

    public var energyGainedThisStep: Int = 0;
    public var currentDirection: Direction = Direction.None;

    public function new(species: Species) {
        this.species = species;
        this.drawable = new h2d.Layers();
        this.updateDrawable();
    }

    public function set_x(x: Int): Int {
        this.x = x;
        this.drawable.x = (this.x * Constants.GridSize) + (
                (Constants.GridSize - (this.size * Constants.GridSize))/2);
        return this.x;
    }

    public function set_y(y: Int): Int {
        this.y = y;
        this.drawable.y = (this.y * Constants.GridSize) + (
                (Constants.GridSize - (this.size * Constants.GridSize))/2);
        return this.y;
    }

    public function updateDrawable() {
        this.size = Math.max(0.5, Math.min(1.0, 0.5+age/100));
        this.drawable.scaleX = this.size;
        this.drawable.scaleY = this.size;
        this.drawable.x = (this.x * Constants.GridSize) + (
                (Constants.GridSize - (this.size * Constants.GridSize))/2);
        this.drawable.y = (this.y * Constants.GridSize) + (
                (Constants.GridSize - (this.size * Constants.GridSize))/2);
    }

    public function set_age(age: Int): Int {
        this.age = age;
        this.updateDrawable();
        return this.age;
    }

    public function processMove(world: World) {
        this.species.processMove(this, world);
    }
    public function processExtract(world: World) {
        this.species.processExtract(this, world);
    }
    public function processProduce(world: World) {
        this.species.processProduce(this, world);
    }
    public function processReproduce(world: World) {
        this.species.processReproduce(this, world);
    }
    public function processAge(world: World) {
        this.species.processAge(this, world);
    }
    public function processDie(world: World) {
        this.species.processDie(this, world);
    }
    public function processDecay(world: World) {
        this.species.processDecay(this, world);
    }

    public function get_isAlive(): Bool {
        return this.energy > 0;
    }

    public function get_type(): String {
        return this.species.genericType;
    }
}

