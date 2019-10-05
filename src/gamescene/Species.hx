
package gamescene;

class Species {

    var assets: common.Assets;

    public function new(assets: common.Assets) {
        this.assets = assets;
    }

    public function newLife(): Life {
        return null;
    }
}

class PlantSpecies extends Species{

    var fill: common.Assets.Tile;
    var deco: common.Assets.Tile;

    public function new(assets: common.Assets) {
        super(assets);

        this.fill = assets.getAsset("plant_fill").tiles[0].copy();
        this.fill.color = new h3d.Vector(0.1, 0.8, 0.1);
        this.deco = assets.getAsset("plant_deco").tiles[common.MathUtils.random(0, 2)].copy();
        this.deco.color = new h3d.Vector(1, 1, 1, 0.4);
    }

    override public function newLife(): Life {
        var life = new Life.PlantLife(this);
        life.drawable.add(this.fill.getBitmap(), 0);
        life.drawable.add(this.deco.getBitmap(), 1);
        return life;
    }
}

class AnimalSpecies extends Species {

    var fill: common.Assets.Tile;
    var skin: common.Assets.Tile;
    var eye: common.Assets.Tile;

    public function new(assets: common.Assets) {
        super(assets);

        this.fill = assets.getAsset("animal_fill").tiles[0].copy();
        this.fill.color = new h3d.Vector(0.1, 0.1, 0.8);
        this.skin = assets.getAsset("animal_skins").tiles[common.MathUtils.random(0, 2)].copy();
        this.skin.color = new h3d.Vector(1, 1, 1, 0.4);
        this.eye = assets.getAsset("animal_eyes").tiles[common.MathUtils.random(0, 1)].copy();
        this.eye.color = new h3d.Vector(0, 0, 0, 0.4);
    }

    override public function newLife(): Life {
        var life = new Life.AnimalLife(this);
        life.drawable.add(this.fill.getBitmap(), 0);
        life.drawable.add(this.skin.getBitmap(), 1);
        life.drawable.add(this.eye.getBitmap(), 2);
        return life;
    }
}
