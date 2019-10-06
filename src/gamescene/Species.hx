
package gamescene;

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
        this.x += 7;
        this.y += 4;
        this.isHovered = false;
    }

    public function hover() {
        if (this.isHovered || this.isSelected) return;

        this.scaleX = 1.1;
        this.scaleX = 1.1;
        this.x -= 7;
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
}

class PlantSpecies extends Species{

    var fill: common.Assets.Tile;
    var deco: common.Assets.Tile;

    public var energyMultiplier(default, null): Float = 5.0;
    public var energyConsumption(default, null): Int = 25;
    public var reproductionChance(default, null): Int = 5;
    public var reproductionEnergyRequirement(default, null): Int = 100;
    public var reproductionAgeRequirement(default, null): Int = 10;
    public var ageNutrientsMultiplier(default, null):Float = 7;
    public var nutrientAbsorptionRate(default, null):Int = 10;

    public var _drawable: SpCard;

    public function new(assets: common.Assets) {
        super(assets);

        this.fill = assets.getAsset("plant_fill").tiles[0].copy();
        this.fill.color = new h3d.Vector(0.1, 0.8, 0.1);
        this.deco = assets.getAsset("plant_deco").tiles[common.MathUtils.random(0, 2)].copy();
        this.deco.color = new h3d.Vector(1, 1, 1, 0.4);

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
        var d = this.deco.getBitmap();
        layer.add(d, 2);
        layer.scaleX = 1.5;
        layer.scaleY = 1.5;
        layer.x = 6;
        layer.y = 6;
        return layer;
    }

    override public function newLife(): Life {
        var life = new Life.PlantLife(this);
        life.drawable.add(this.fill.getBitmap(), 0);
        life.drawable.add(this.deco.getBitmap(), 1);
        return life;
    }

    override public function get_drawable(): SpCard {
        return _drawable;
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
        layer.x = 6;
        layer.y = 6;
        return layer;
    }

    override public function newLife(): Life {
        var life = new Life.AnimalLife(this);
        life.drawable.add(this.fill.getBitmap(), 0);
        life.drawable.add(this.skin.getBitmap(), 1);
        life.drawable.add(this.eye.getBitmap(), 2);
        return life;
    }

    override public function get_drawable(): SpCard {
        return _drawable;
    }
}
