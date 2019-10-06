
package gamescene;

import haxe.ds.Vector;
import common.Direction;

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
    public var genericType(get, null): String;

    public var drawable(get, null): SpCard;

    public function new(assets: common.Assets) {
        this.assets = assets;
    }

    public function newLife(): Life {
        return null;
    }

    public function get_drawable(): SpCard {
        return null;
    }

    public function processMove(life: Life, world: World) {}
    public function processExtract(life: Life, world: World) {}
    public function processProduce(life: Life, world: World) {}
    public function processReproduce(life: Life, world: World) {}
    public function processAge(life: Life, world: World) {
        life.age += 1;
    }
    public function processDie(life: Life, world: World) {}
    public function processDecay(life: Life, world: World) {}

    public function get_genericType(): String {
        return "undefined";
    }
}

class PlantSpecies extends Species{

    var tiles: common.Assets.Asset2D;

    public var energyMultiplier(default, null): Float = 5.0;
    public var energyConsumption(default, null): Int = 25;
    public var reproductionChance(default, null): Int = 5;
    public var reproductionEnergyRequirement(default, null): Int = 100;
    public var reproductionAgeRequirement(default, null): Int = 10;
    public var ageNutrientsMultiplier(default, null):Float = 7;
    public var nutrientAbsorptionRate(default, null):Int = 10;

    public var _drawable: SpCard;

    public function new(assets: common.Assets, tiles: common.Assets.Asset2D) {
        super(assets);
        this.tiles = tiles;
        this._drawable = this.makeCard();
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

    override public function newLife(): Life {
        var life = new Life(this);
        var bitmap = this.tiles.getBitmap(2);
        life.drawable.add(bitmap, 0);
        return life;
    }

    override public function get_drawable(): SpCard {
        return _drawable;
    }

    function canReproduce(life: Life, world: World) {
        return (life.energy > this.reproductionEnergyRequirement &&
                life.age > this.reproductionAgeRequirement);
    }

    override function get_genericType(): String {
        return "plant";
    }

    override function processExtract(life: Life, world: World) {
        life.energyGainedThisStep = 0;
        // Try extract current cell first
        var cell = world.cells[life.x][life.y];
        var drained:Int = 0;
        var have = hxd.Math.imin(cell.nutrients, this.nutrientAbsorptionRate - drained);
        drained += have;
        cell.nutrients -= have;

        if (drained != this.nutrientAbsorptionRate) {
            // extract from surrounding
            var cellList = common.GridUtils.getAround(world.cells, [life.x, life.y], 2);
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
                if (drained == this.nutrientAbsorptionRate) {
                    break;
                }
            }
        }
        drained = Math.floor(this.energyMultiplier * drained);
        life.energy += drained;
        life.energyGainedThisStep = drained;
    }

    override function processAge(life: Life, world: World) {
        super.processAge(life, world);
        life.energy -= hxd.Math.imin(life.energy, this.energyConsumption);
    }

    override public function processReproduce(life: Life, world: World) {
        if (!this.canReproduce(life, world)) {
            return;
        }

        var chance = this.reproductionChance;
        if (life.energyGainedThisStep == 0) {
            chance += 20;
        }
        if (Random.int(0, 1000) > chance) {
            return;
        }

        var cellList = common.GridUtils.getAround(world.cells, [life.x, life.y], 2);
        Random.shuffle(cellList);

        for (cell in cellList) {
            if (cell.plant != null) {
                continue;
            }

            var life = this.newLife();
            life.x = cell.x;
            life.y = cell.y;
            world.addLife(life);
            break;
        }

    }

    override public function processDie(life: Life, world: World) {
        var cellList = common.GridUtils.getAround(world.cells, [life.x, life.y], 2);
        cellList.push(world.cells[life.x][life.y]);
        Random.shuffle(cellList);
        var newNutrients = life.age * this.ageNutrientsMultiplier;
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

class Tree extends PlantSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("tree"));
    }
}

class Bush extends PlantSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("bush"));
    }
}

class Fungus extends PlantSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("fungus"));
    }
}

class Grass extends PlantSpecies {
    public function new(assets: common.Assets) {
        super(assets, assets.getAsset("grass"));
    }
}

class AnimalSpecies extends Species {

    var fill: common.Assets.Tile;
    var skin: common.Assets.Tile;
    var eye: common.Assets.Tile;

    public var energyMultiplier(default, null): Float = 5.0;
    public var nutrientAbsorptionRate(default, null):Int = 10;
    public var ageNutrientsMultiplier(default, null): Float = 2;
    public var energyConsumption(default, null): Int = 25;
    public var reproductionChance(default, null): Int = 1;
    public var reproductionEnergyRequirement(default, null): Int = 100;
    public var reproductionAgeRequirement(default, null): Int = 10;
    public var maxEnergy(default, null): Int = 500;

    public var _drawable: SpCard;

    public function new(assets: common.Assets) {
        super(assets);

        this.fill = assets.getAsset("animal_fill").tiles[0].copy();
        this.fill.color = new h3d.Vector(0.1, 0.1, 0.8);
        this.skin = assets.getAsset("animal_skins").tiles[common.MathUtils.random(0, 2)].copy();
        this.skin.color = new h3d.Vector(1, 1, 1, 0.4);
        this.eye = assets.getAsset("animal_eyes").tiles[common.MathUtils.random(0, 1)].copy();
        this.eye.color = new h3d.Vector(0, 0, 0, 0.4);

        this._drawable = this.makeCard();
    }

    function makeCard(): SpCard {
        var layer = new SpCard(this.assets);
        layer.add(this.makeLifeImage(), 1);
        return layer;
    }

    function makeLifeImage(): h2d.Layers {
        var layer = new h2d.Layers();
        var f = this.fill.getBitmap();
        layer.add(f, 1);
        var s = this.skin.getBitmap();
        layer.add(s, 2);
        var e = this.eye.getBitmap();
        layer.scaleX = 1.5;
        layer.scaleY = 1.5;
        layer.x = 12;
        layer.y = 6;
        return layer;
    }

    override public function newLife(): Life {
        var life = new Life(this);
        life.drawable.add(this.fill.getBitmap(), 0);
        life.drawable.add(this.skin.getBitmap(), 1);
        life.drawable.add(this.eye.getBitmap(), 2);
        return life;
    }

    override public function get_drawable(): SpCard {
        return _drawable;
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
        if (life.energy < this.maxEnergy && cell.nutrients > 0) return;

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

    function changeDirection(life: Life) {
        var availableDirection = [Direction.Left, Direction.Up, Direction.Right, Direction.Down];
        availableDirection = availableDirection.filter(function(d: Direction) {
            return d != life.currentDirection && d != common.Direction.Utils.opposite(life.currentDirection);
        });
        life.currentDirection = Random.fromArray(availableDirection);
    }

    override public function processExtract(life: Life, world: World) {
        trace(life);
        if (life.energy > this.maxEnergy) {
            return;
        }

        var cell = world.cells[life.x][life.y];
        var drained:Int = 0;
        var have = hxd.Math.imin(cell.nutrients, this.nutrientAbsorptionRate - drained);

        drained += have;
        cell.nutrients -= have;

        life.energy += Math.floor(this.energyMultiplier * drained);
    }

    public function canReproduce(life: Life): Bool {
        return (life.energy > this.reproductionEnergyRequirement &&
                life.age > this.reproductionAgeRequirement);
    }

    override public function processReproduce(life: Life, world: World) {
        if (!this.canReproduce(life)) {
            return;
        }

        var chance = this.reproductionChance + (life.energy/200);
        if (Random.int(0, 1000) > chance) {
            return;
        }

        var cellList = common.GridUtils.getAround(world.cells, [life.x, life.y], 2);
        Random.shuffle(cellList);

        for (cell in cellList) {
            if (cell.plant != null) {
                continue;
            }

            var life = this.newLife();
            life.x = cell.x;
            life.y = cell.y;
            world.addLife(life);
            break;
        }

    }

    override public function processAge(life: Life, world: World) {
        super.processAge(life, world);
        life.energy -= hxd.Math.imin(life.energy, this.energyConsumption);
    }

    override public function processDie(life: Life, world: World) {
        var newNutrients = Math.floor(life.age * this.ageNutrientsMultiplier);
        var cell = world.cells[life.x][life.y];
        cell.nutrients += newNutrients;
    }

    override public function get_genericType(): String {
        return "animal";
    }
}
