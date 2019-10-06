
package gamescene;

import haxe.ds.Vector;
import common.Direction;

class Life {

    var species: Species;

    public var age: Int = 0;
    public var drawable: h2d.Layers;

    public var x(default, set): Int = 0;
    public var y(default, set): Int = 0;

    public var energy: Int = 0;
    public var mass: Int = 0;

    public var isAlive(get, null): Bool;

    public var type(get, null): String;

    public var energyGainedThisStep: Int = 0;
    public var lastProducedAge: Int = 0;
    public var currentDirection: Direction = Direction.None;
    public var stage: Int = 0;
    public var isDead: Bool = false;

    public var numOffspring: Int = 0;

    public function new(species: Species) {
        this.species = species;
        this.drawable = new h2d.Layers();
        this.drawable.x = (this.x * Constants.GridSize);
        this.drawable.y = (this.y * Constants.GridSize);
    }

    public function set_x(x: Int): Int {
        this.x = x;
        this.drawable.x = (this.x * Constants.GridSize);
        return this.x;
    }

    public function set_y(y: Int): Int {
        this.y = y;
        this.drawable.y = (this.y * Constants.GridSize);
        return this.y;
    }

    public function set_age(age: Int): Int {
        this.age = age;
        return this.age;
    }

    public function die() {
        this.isDead = true;
        var c = this.drawable.getChildAt(0);
        if (c != null) {
            var v: h2d.Bitmap = Std.downcast(c, h2d.Bitmap);
            if (v != null) {
                v.color = h3d.Vector.fromColor(0xFF333333);
            }
        }
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
    public function processConsume(world: World) {
        this.species.processConsume(this, world);
    }
    public function processGrowth(world: World) {
        this.species.processGrowth(this, world);
    }
    public function processDie(world: World) {
        this.species.processDie(this, world);
    }
    public function processDecay(world: World) {
        this.species.processDecay(this, world);
    }

    public function get_isAlive(): Bool {
        return !this.isDead;
    }

    public function get_type(): String {
        return this.species.genericType;
    }
}

