
package gamescene;

import haxe.ds.Vector;
import common.Direction;

class Life {

    public var age(default, set): Int = 0;
    public var drawable: h2d.Layers;

    public var x(default, set): Int = 0;
    public var y(default, set): Int = 0;

    public var energy: Int = 0;
    public var size: Float = 0.5;
    public var isAlive(get, null): Bool;

    public var type(get, null): String;

    public function new() {
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

    public function processMove(world: World) {}
    public function processExtract(world: World) {}
    public function processProduce(world: World) {}
    public function processReproduce(world: World) {}
    public function processAge(world: World) {
        this.age += 1;
    }
    public function processDie(world: World) {}

    public function get_isAlive(): Bool {
        return this.energy > 0;
    }

    public function get_type(): String {
        return "life";
    }
}

class PlantLife extends Life {

    var species: Species.PlantSpecies;

    var energyMultiplier: Float = 5.0;
    var energyConsumption: Int = 25;
    var reproductionChance: Int = 10;
    var reproductionEnergyRequirement: Int = 100;
    var reproductionAgeRequirement: Int = 10;
    var ageNutrientsMultiplier = 7;
    var nutrientAbsorptionRate = 10;

    public var canReproduce(get, null): Bool;

    override public function get_type(): String { return "plant"; }

    public function new(sp: Species.PlantSpecies) {
        super();
        this.species = sp;
    }

    override public function processExtract(world: World) {
        // Try extract current cell first
        var cell = world.cells[this.x][this.y];
        var drained:Int = 0;
        var have = hxd.Math.imin(cell.nutrients, this.nutrientAbsorptionRate - drained);
        drained += have;
        cell.nutrients -= have;

        if (drained != this.nutrientAbsorptionRate) {
            // extract from surrounding
            var cellList = common.GridUtils.getAround(world.cells, [this.x, this.y], 2);
            Random.shuffle(cellList);

            for (cell in cellList) {
                if (cell == null) {
                    continue;
                }
                if (cell.nutrients > 0) {
                    have = hxd.Math.imin(cell.nutrients, this.nutrientAbsorptionRate - drained);
                    drained += have;
                    cell.nutrients -= have;
                }
                if (drained == this.nutrientAbsorptionRate){
                    break;
                }
            }
        }

        this.energy += Math.floor(this.energyMultiplier * drained);
    }

    public function get_canReproduce(): Bool {
        return this.energy > this.reproductionEnergyRequirement && this.age > this.reproductionAgeRequirement;
    }

    override public function processAge(world: World) {
        super.processAge(world);
        this.energy -= hxd.Math.imin(this.energy, this.energyConsumption);
    }

    override public function processReproduce(world: World) {
        if (!this.canReproduce) {
            return;
        }
        if (Random.int(0, 1000) > this.reproductionChance) {
            return;
        }

        var cellList = common.GridUtils.getAround(world.cells, [this.x, this.y], 2);
        Random.shuffle(cellList);

        for (cell in cellList) {
            if (cell.plant != null) {
                continue;
            }

            var life = this.species.newLife();
            world.moveLife(life, [cell.x, cell.y]);
            break;
        }

    }

    override public function processDie(world: World) {
        var cellList = common.GridUtils.getAround(world.cells, [this.x, this.y], 2);
        cellList.push(world.cells[this.x][this.y]);
        Random.shuffle(cellList);
        var newNutrients = this.age * this.ageNutrientsMultiplier;
        var spread = Math.floor(newNutrients / 2 / cellList.length);
        // 50% evenly spread
        for (cell in cellList) {
            cell.nutrients += spread;
        }
        spread = Math.floor(newNutrients / 2 / 10);
        for (i in 0...10) {
            Random.fromArray(cellList).nutrients += spread;
        }
    }
}

class AnimalLife extends Life {

    var species: Species.AnimalSpecies;

    var energyMultiplier: Float = 5.0;
    var nutrientAbsorptionRate = 10;
    var ageNutrientsMultiplier: Float = 2;
    var energyConsumption: Int = 25;

    var currentDirection: Direction = Direction.None;

    override public function get_type(): String { return "animal"; }

    public function new(sp: Species.AnimalSpecies) {
        super();
        this.species = sp;
        this.energy = 1;
    }

    function shouldChangeDirection(): Bool {
        if (this.currentDirection == Direction.None) {
            return true;
        }
        if (Random.int(0, 1000) < 250) {
            return true;
        }
        return false;
    }

    override public function processMove(world: World) {
        var cell = world.cells[this.x][this.y];
        if (cell.nutrients > 0) return;

        if (this.shouldChangeDirection()) {
            this.changeDirection();
        }

        var point = common.Direction.Utils.directionToCoord(this.currentDirection);
        point = [this.x + point.x, this.y + point.y];
        if (!world.inBound(point)) {
            this.changeDirection();
            point = common.Direction.Utils.directionToCoord(this.currentDirection);
            point = [this.x + point.x, this.y + point.y];
        }
        world.moveLife(this, point);
    }

    function changeDirection() {
        var availableDirection = [Direction.Left, Direction.Up, Direction.Right, Direction.Down];
        availableDirection = availableDirection.filter(function(d: Direction) {
            return d != this.currentDirection && d != common.Direction.Utils.opposite(this.currentDirection);
        });
        this.currentDirection = Random.fromArray(availableDirection);
    }

    override public function processExtract(world: World) {
        var cell = world.cells[this.x][this.y];
        var drained:Int = 0;
        var have = hxd.Math.imin(cell.nutrients, this.nutrientAbsorptionRate - drained);

        drained += have;
        cell.nutrients -= have;

        this.energy += Math.floor(this.energyMultiplier * drained);
    }
    override public function processProduce(world: World) {}
    override public function processReproduce(world: World) {}
    override public function processAge(world: World) {
        super.processAge(world);
        this.energy -= hxd.Math.imin(this.energy, this.energyConsumption);
    }
    override public function processDie(world: World) {
        var newNutrients = Math.floor(this.age * this.ageNutrientsMultiplier);
        var cell = world.cells[this.x][this.y];
        cell.nutrients += newNutrients;
    }
}
