
package gamescene;

import haxe.ds.Vector;
import common.Direction;
import common.Point2i;

class SpCard extends h2d.Layers {

    var spcard: h2d.Bitmap;

    var isHovered: Bool = false;
    var isSelected: Bool = false;

    public function new(assets: common.Assets) {
        super();
        this.spcard = assets.getAsset("spcard").tiles[0].getBitmap();
        this.add(spcard, 0);
    }

    public function unhover() {
        if (!this.isHovered) return;

        this.scaleX = 1.0;
        this.scaleX = 1.0;
        this.x += 3;
        this.y += 4;
        this.isHovered = false;
    }

    public function hover() {
        if (this.isHovered || this.isSelected) return;

        this.scaleX = 1.1;
        this.scaleX = 1.1;
        this.x -= 3;
        this.y -= 4;

        this.isHovered = true;
    }

    public function select() {
        if (this.isSelected) return;
        if (this.isHovered) this.unhover();

        this.spcard.color = new h3d.Vector(1.0, 1.0, 0.6);
        this.isSelected = true;
    }

    public function unselect() {
        if (!this.isSelected) return;
        this.spcard.color = new h3d.Vector(1.0, 1.0, 1.0);
        this.isSelected = false;
    }

    public function toggleSelect(): Bool {
        if (this.isSelected) {
            this.unselect();
        } else {
            this.select();
        }
        return this.isSelected;
    }
}

class Species {

    var assets: common.Assets;
    var tiles: common.Assets.Asset2D;
    public var genericType(get, null): String;
    public var drawable: SpCard;

    var growRequirement: Array<Int> = [50, 100];

    public var nameString(default, null): String = 'Species Name';
    public var typeString(default, null): String = 'Species Type';
    public var description(default, null): String = 'This is the description for the species.\nPut more information here.';
    public var detail(default, null): String = '';

    public function new(assets: common.Assets, tiles: common.Assets.Asset2D) {
        this.assets = assets;
        this.tiles = tiles;
        this.drawable = this.makeCard();
    }

    public function newLife(): Life {
        var life = new Life(this);
        var bitmap = this.tiles.getBitmap(0);
        life.drawable.add(bitmap, 0);
        return life;
    }

    public function get_drawable(): SpCard {
        return null;
    }

    public function processMove(life: Life, world: World) {}
    public function processExtract(life: Life, world: World) {}
    public function processProduce(life: Life, world: World) {}
    public function processConsume(life: Life, world: World) {}
    public function processReproduce(life: Life, world: World) {}
    public function processGrowth(life: Life, world: World) {
        life.age += 1;
        if (life.stage < this.growRequirement.length && life.age == this.growRequirement[life.stage] ) {
            life.stage += 1;
            life.drawable.removeChildren();
            life.drawable.add(this.tiles.getBitmap(life.stage), 0);
        }
    }
    public function processDie(life: Life, world: World) {}
    public function processDecay(life: Life, world: World) {}

    public function get_genericType(): String {
        return "undefined";
    }

    function makeCard(): SpCard {
        var layer = new SpCard(this.assets);
        var l = this.makeLifeImage();
        l.x = 12; l.y = 6;
        layer.add(l, 1);
        return layer;
    }

    function makeLifeImage(): h2d.Layers {
        var layer = new h2d.Layers();
        var bitmap = this.tiles.getBitmap(2);
        layer.add(bitmap, 0);
        layer.scaleX = 1.5;
        layer.scaleY = 1.5;
        return layer;
    }

    public function shouldDie(life: Life): Bool {
        return false;
    }

}

class PlantSpecies extends Species{

    public var energyMultiplier(default, null): Float = 5.0;
    public var consumptionRate(default, null): Int = 25;
    public var reproductionChance(default, null): Int = 5;
    public var reproductionEnergyRequirement(default, null): Int = 100;
    public var reproductionAgeRequirement(default, null): Int = 10;
    public var reproductionMassRequirement(default, null): Int = 100;
    public var ageNutrientsMultiplier(default, null):Float = 7;
    public var nutrientAbsorptionRate(default, null):Int = 10;
    public var extractRange(default, null): Int = 1;
    public var autoDie(default, null): Bool = true;
    public var maxMass(default, null): Int = -1;

    public var massPerTurn:Int = 1;
    public var requiredEnergyPerFood: Int = 10;
    public var foodPerProduction: Int = 0;
    public var productionTurn: Int = 0;
    public var minimumProductionAge: Int = 100;
    public var produceRange: Int = 0;
    public var reproduceRange: Int = 1;

    public function new(assets: common.Assets, tiles: common.Assets.Asset2D) {
        super(assets, tiles);
    }

    override function get_genericType(): String {
        return "plant";
    }

    function canReproduce(life: Life, world: World) {
        return (life.energy >= this.reproductionEnergyRequirement &&
                life.age >= this.reproductionAgeRequirement &&
                life.mass >= this.reproductionMassRequirement
        );
    }

    override function processConsume(life: Life, world: World) {
        var consumed = hxd.Math.imin(life.energy, this.consumptionRate);
        life.energy -= consumed;
        if (this.autoDie && life.energy == 0) {
            life.die();
        }
    }

    override function processExtract(life: Life, world: World) {
        life.energyGainedThisStep = 0;
        // Try extract current cell first
        var drained:Int = 0;
        var need: Int = this.nutrientAbsorptionRate;
        var have = world.drainNutrients([life.x, life.y], need);
        drained += have;
        need -= have;

        if (need > 0) {
            // extract from surrounding
            var cellList = common.GridUtils.getPointsAround(
                    [life.x, life.y], this.extractRange,
                    [0, 0, world.cells.length-1, world.cells[0].length-1]);
            Random.shuffle(cellList);

            for (cell in cellList) {
                have = world.drainNutrients([cell.x, cell.y], need);
                drained += have;
                need -= have;
                if (need == 0) {
                    break;
                }
            }
        }

        drained = Math.floor(this.energyMultiplier * drained);
        life.energy += drained;
        life.energyGainedThisStep = drained;
    }

    override function processGrowth(life: Life, world: World) {
        super.processGrowth(life, world);
        var consume = hxd.Math.imin(life.energy, this.consumptionRate);
        life.energy -= consume;
        if (consume > 0) {
            life.mass += massPerTurn;
        }
        if (this.maxMass != -1) {
            life.mass = hxd.Math.imin(life.mass, this.maxMass);
        }
    }

    override function processProduce(life: Life, world: World) {
        super.processProduce(life, world);

        if (life.age < this.minimumProductionAge) return;

        if (this.productionTurn != 0 && (life.age - life.lastProducedAge) > this.productionTurn) {
            if (life.energy > (this.requiredEnergyPerFood * this.foodPerProduction)) {
                var energyUsed = this.foodPerProduction * this.requiredEnergyPerFood;
                // convert to int because energy used might not be multiple of requiredEnergyPerFood
                life.energy -= energyUsed;
                var cellList = common.GridUtils.getPointsAround(
                        [life.x, life.y], this.produceRange,
                        [0, 0, world.cells.length-1, world.cells[0].length-1],
                        false);
                var point = Random.shuffle(cellList);
                for (cell in cellList) {
                    if (world.addFood(cell, this.foodPerProduction)) break;
                }
                life.lastProducedAge = life.age;
            }
        }
    }

    override public function processReproduce(life: Life, world: World) {
        if (!this.canReproduce(life, world)) {
            return;
        }

        var chance = this.getReproductionChance(life, world);
        if (Random.int(0, 1000) > chance) {
            return;
        }

        var cellList = common.GridUtils.getAround(world.cells, [life.x, life.y], this.reproduceRange, false);
        Random.shuffle(cellList);

        for (cell in cellList) {
            if (cell.plant != null) {
                continue;
            }

            var life = this.newLife();
            life.x = cell.x;
            life.y = cell.y;
            world.addLife(life);
            life.numOffspring += 1;
            break;
        }

    }

    override public function processDie(life: Life, world: World) {
        var cellList = common.GridUtils.getAround(world.cells, [life.x, life.y], 2);
        cellList.push(world.cells[life.x][life.y]);
        Random.shuffle(cellList);
        var newNutrients = life.mass * Constants.NutrientPerMass;
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

    public function getReproductionChance(life: Life, world: World): Int {
        return this.reproductionChance;
    }
}

class Tree extends PlantSpecies {

    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("tree"));
        this.nameString = "Tree";
        this.typeString = "plant";

        // set up tree parameters
        this.extractRange = 2;
        this.energyMultiplier = 20.0;
        this.nutrientAbsorptionRate = 2;
        // energy/turn = 100
        // lose 10 energy per turn
        this.consumptionRate = 5;
        // consume 5 energy to stay alive
        // gain 10 mass per turn
        this.massPerTurn = 1;
        // Dont die when no energy
        this.autoDie = false;

        this.reproductionChance = 1;
        this.reproductionEnergyRequirement = 0;
        this.reproductionAgeRequirement = 300;
        this.reproductionMassRequirement = 1000;
        this.reproduceRange = 2;

        this.foodPerProduction = 100;
        this.productionTurn = 50;
        this.minimumProductionAge = 100;
        this.produceRange = 2;

        this.description = (
                'Tree a simple plant that is able to extract nutrients from soil\n'+
                'It is efficient in converting nutrients to energy\n'+
                'It does not lose much energy, and many of the energy are stored.\n'+
                'Tree will not die if it runs out of energy'
        );
    }
}

class Bush extends PlantSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("bush"));

        this.nameString = "Bush";
        this.typeString = "plant";

        this.extractRange = 1;
        this.energyMultiplier = 12.0;
        this.nutrientAbsorptionRate = 5;

        this.consumptionRate = 5;
        this.massPerTurn = 1;
        this.autoDie = true;
        this.maxMass = 100;

        this.reproductionChance = 10;
        this.reproductionEnergyRequirement = 0;
        this.reproductionAgeRequirement = 50;
        this.reproductionMassRequirement = 0;
        this.growRequirement = [25, 50];

        this.foodPerProduction = 10;
        this.productionTurn = 2;
        this.produceRange = 1;

        this.description = (
                'Bush a plant that is able to extract nutrients from soil\n'+
                'It will grow fast and produce constant amount of food\n'+
                'Unlike tree, bushes will die when it runs out of energy'
        );
    }

    override public function getReproductionChance(life: Life, world: World): Int {
        if (life.numOffspring> 2) return 0;
        return this.reproductionChance + (life.energyGainedThisStep == 0 ? 50 : 0);
    }
}

class Fungus extends PlantSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("fungus"));

        this.nameString = "Fungus";
        this.typeString = "fungus";

        this.extractRange = 1;
        this.energyMultiplier = 10.0;
        this.nutrientAbsorptionRate = 10;

        this.consumptionRate = 50;
        this.massPerTurn = 10;
        this.autoDie = true;

        this.reproductionChance = 100;
        this.reproductionEnergyRequirement = 100;
        this.reproductionAgeRequirement = 15;
        this.reproductionMassRequirement = 0;
        this.growRequirement = [25, 50];

        this.description = (
                'Fungus is a rapid growing organism that will spread very fast\n'+
                'If not controlled, it will destroy your ecosystem\nby rapidly deplete your nutrients.\n'+
                'Fungus will die once it runs out of energy'
        );
    }
}

class Grass extends PlantSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("grass"));

        this.nameString = "Grass";
        this.typeString = "plant";

        this.extractRange = 0;
        this.energyMultiplier = 20.0;
        this.nutrientAbsorptionRate = 2;

        this.consumptionRate = 5;
        this.massPerTurn = 1;
        this.autoDie = false;

        this.reproductionChance = 1;
        this.reproductionEnergyRequirement = 0;
        this.reproductionAgeRequirement = 15;
        this.reproductionMassRequirement = 0;
        this.growRequirement = [25, 50];

        this.description = (
                'Grass is a rapid growing plant.\n'+
                'It will not die when it runs out of energy.\n' +
                'A favourite food for the insect\n'+
                'Grass will not die if it runs out of energy'
        );
    }

    override public function getReproductionChance(life: Life, world: World): Int {
        return this.reproductionChance + (life.energyGainedThisStep == 0 ? 10 : 0);
    }
}

class AnimalSpecies extends Species {

    var fill: common.Assets.Tile;
    var skin: common.Assets.Tile;
    var eye: common.Assets.Tile;

    public var energyMultiplier(default, null): Float = 10.0;
    public var nutrientAbsorptionRate(default, null):Int = 20;
    public var consumptionRate(default, null): Int = 50;
    public var reproductionChance(default, null): Int = 10;
    public var reproductionEnergyRequirement(default, null): Int = 0;
    public var reproductionAgeRequirement(default, null): Int = 100;
    public var maxEnergy(default, null): Int = 5000;
    public var maxMass: Int = 1000;
    public var massPerTurn: Int = 3;
    public var startingEnergy: Int = 500;
    public var dieNutrientsRange: Int = 2;

    public var _drawable: SpCard;

    public function new(assets: common.Assets, tiles: common.Assets.Asset2D) {
        super(assets, tiles);
    }

    override public function newLife(): Life {
        var life = super.newLife();
        life.energy = this.startingEnergy;
        return life;
    }

    override public function get_genericType(): String {
        return "animal";
    }

    function shouldChangeDirection(life: Life): Bool {
        if (life.currentDirection == Direction.None) {
            return true;
        }
        if (Random.int(0, 1000) < 250) {
            return true;
        }
        return false;
    }

    override public function processMove(life: Life, world: World) {
        var cell = world.cells[life.x][life.y];
        if (!this.shouldMove(life, world)) return;

        if (this.shouldChangeDirection(life)) {
            this.changeDirection(life);
        }

        var point = common.Direction.Utils.directionToCoord(life.currentDirection);
        point = [life.x + point.x, life.y + point.y];
        if (!world.inBound(point)) {
            this.changeDirection(life);
            point = common.Direction.Utils.directionToCoord(life.currentDirection);
            point = [life.x + point.x, life.y + point.y];
        }
        world.moveLife(life, point);
    }

    function shouldMove(life: Life, world: World): Bool {
        return true;
    }

    override function processGrowth(life: Life, world: World) {
        super.processGrowth(life, world);
        var consume = hxd.Math.imin(life.energy, this.consumptionRate);
        life.energy -= consume;
        if (consume > 0) {
            life.mass += massPerTurn;
        }
        if (this.maxMass != -1) {
            life.mass = hxd.Math.imin(life.mass, this.maxMass);
        }
    }

    function changeDirection(life: Life) {
        var availableDirection = [Direction.Left, Direction.Up, Direction.Right, Direction.Down];
        availableDirection = availableDirection.filter(function(d: Direction) {
            return d != life.currentDirection && d != common.Direction.Utils.opposite(life.currentDirection);
        });
        life.currentDirection = Random.fromArray(availableDirection);
    }

    public function canReproduce(life: Life): Bool {
        return (life.energy > this.reproductionEnergyRequirement &&
                life.age > this.reproductionAgeRequirement);
    }

    override public function processReproduce(life: Life, world: World) {
        if (!this.canReproduce(life)) {
            return;
        }

        var chance = this.getReproductionChance(life, world);
        if (Random.int(0, 1000) > chance) {
            return;
        }

        var cellList = common.GridUtils.getAround(world.cells, [life.x, life.y], 2);
        Random.shuffle(cellList);

        for (cell in cellList) {
            if (cell.plant != null) {
                continue;
            }

            var newLife = this.reproduce(life);
            newLife.x = cell.x;
            newLife.y = cell.y;
            world.addLife(newLife);
            break;
        }
    }

    public function reproduce(life: Life): Life {
        return this.newLife();
    }

    override public function processDie(life: Life, world: World) {
        var cellList = common.GridUtils.getAround(world.cells, [life.x, life.y], this.dieNutrientsRange);
        cellList.push(world.cells[life.x][life.y]);
        Random.shuffle(cellList);
        var newNutrients = life.mass * Constants.NutrientPerMass + Math.floor(life.energy / Constants.EnergyPerNutrient);
        trace('new nutrients: ${newNutrients}');
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

    public function getReproductionChance(life: Life, world: World): Int {
        return this.reproductionChance;
    }

    override function processConsume(life: Life, world: World) {
        var consumed = hxd.Math.imin(life.energy, this.consumptionRate);
        life.energy -= consumed;
        if (life.energy == 0) {
            life.die();
        }
    }
}

class Slime extends AnimalSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("slime"));

        this.nameString = "Slime";
        this.typeString = "unknown";

        this.energyMultiplier = 10.0;
        this.nutrientAbsorptionRate = 50;
        this.consumptionRate = 100;

        this.maxEnergy = 10000;
        this.maxMass = -1;
        this.massPerTurn = 9;
        this.dieNutrientsRange = 4;

        this.description = (
                'Slime is a nutrient absorbing creature.\n' +
                'Most of what is absorbed is stored in itself.\n' +
                'When the slime gets bigger, it will split into multiple slime.\n'+
                'The slime will explode into nutrients if it reaches age 200\nif it did not split by then\n'
        );
    }

    override function reproduce(life: Life): Life {
        var newLife = this.newLife();
        life.age = 0;
        newLife.age = 0;
        life.mass = Math.floor(life.mass/2);
        newLife.mass = life.mass;
        life.energy = Math.floor(life.energy/2);
        newLife.mass = life.energy;
        life.drawable.removeChildren();
        life.drawable.add(this.tiles.getBitmap(0), 0);
        return newLife;
    }

    override public function getReproductionChance(life: Life, world: World): Int {
        return Math.floor(life.mass / 5);
    }

    override public function shouldMove(life: Life, world: World): Bool {
        var cell = world.cells[life.x][life.y];
        return !(life.energy < this.maxEnergy && cell.nutrients > 0);
    }

    override public function processExtract(life: Life, world: World) {
        if (life.energy > this.maxEnergy) {
            return;
        }

        var drained:Int = world.drainNutrients([life.x, life.y], this.nutrientAbsorptionRate);
        life.energy += Math.floor(this.energyMultiplier * drained);
    }

    override public function shouldDie(life: Life): Bool {
        return life.age > 200;
    }

}

class Rodent extends AnimalSpecies {

    public var foodAbsorptionRate = 10;
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("rodent"));

        this.nameString = "Rodent";
        this.typeString = "animal";

        this.consumptionRate = 20;
        this.maxEnergy = 5000;
        this.maxMass = 100;
        this.massPerTurn = 1;
        this.energyMultiplier = 50;
        this.foodAbsorptionRate = 10;

        this.description = (
                'Rodent are small creatures that eat the food that tree and\nbushes produces.\n'+
                'It will try to search for the nearest food and move towards it\n'+
                'If it can\' find a food source, it will move around random\nhoping to get close to food'+
                'Rodent also produces nutrients as it move around'
        );
    }

    override public function shouldMove(life: Life, world: World): Bool {
        var cell = world.cells[life.x][life.y];
        return (cell.food == 0);
    }

    override public function processExtract(life: Life, world: World) {
        if (life.energy > this.maxEnergy) {
            return;
        }

        var drained:Int = world.drainFood([life.x, life.y], this.foodAbsorptionRate);
        life.energy += Math.floor(this.energyMultiplier * drained);
    }

    override function processProduce(life: Life, world: World) {
        if (life.energy == 0) return;

        world.addNutrients([life.x, life.y], 2);
    }

    override public function processMove(life: Life, world: World) {
        if (!this.shouldMove(life, world)) {
            life.targetLocation = null;
            return;
        }

        if (life.targetLocation != null && (
                    life.x == life.targetLocation.x && life.y == life.targetLocation.y)) {
            // reach but no food.
            life.targetLocation = null;
        }

        if (life.targetLocation == null) {
            // try to see if there are any food in the surrounding area
            var points = common.GridUtils.getPointsAround(
                    [life.x, life.y], 4,
                    [0, 0, world.cells.length-1, world.cells[0].length-1]
            );
            points.sort(function(p1: Point2i, p2: Point2i): Int {
                return p1.distance([life.x, life.y]) - p2.distance([life.x, life.y]);
            });

            for (p in points) {
                if (world.cells[p.x][p.y].food > 0) {
                    life.targetLocation = p;
                    break;
                }
            }
            // if still null, means we need to go randomly and hope for the best.
            if (life.targetLocation == null) {
                life.targetLocation = Random.fromArray(points);
            }
        }
        this.changeDirection(life);

        var point = common.Direction.Utils.directionToCoord(life.currentDirection);
        point = [life.x + point.x, life.y + point.y];
        if (!world.inBound(point)) {
            this.changeDirection(life);
            point = common.Direction.Utils.directionToCoord(life.currentDirection);
            point = [life.x + point.x, life.y + point.y];
        }
        world.moveLife(life, point);
    }

    override function changeDirection(life: Life) {
        var availableDirection = [Direction.Left, Direction.Up, Direction.Right, Direction.Down];
        if (life.targetLocation != null) {
            // set direction based on target Location
            var diff = life.targetLocation - [life.x, life.y];
            if (Math.abs(diff.x) > Math.abs(diff.y)) {
                life.currentDirection = diff.x > 0 ? Direction.Right : Direction.Left;
            } else {
                life.currentDirection = diff.y > 0 ? Direction.Down : Direction.Up;
            }
            return;
        }
        availableDirection = availableDirection.filter(function(d: Direction) {
            return d != life.currentDirection && d != common.Direction.Utils.opposite(life.currentDirection);
        });
        life.currentDirection = Random.fromArray(availableDirection);
    }
}

class Insect extends AnimalSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("insect"));
    }
}

class Isopod extends AnimalSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("isopod"));
    }
}

class Bird extends AnimalSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("bird"));
    }
}

