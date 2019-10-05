
package gamescene;

class Species {

    var assets: common.Assets;

    var fill: common.Assets.Tile;
    var skin: common.Assets.Tile;
    var eyes: common.Assets.Tile;

    public function new(assets: common.Assets) {
        this.assets = assets;

        this.fill = assets.getAsset("fill").tiles[0].copy();
        this.fill.color = new h3d.Vector(1.0, 0, 0);
        this.skin = assets.getAsset("skins").tiles[common.MathUtils.random(0, 2)].copy();
        this.skin.color = new h3d.Vector(0, 0, 1.0);
        this.eyes = assets.getAsset("eyes").tiles[common.MathUtils.random(0, 1)].copy();
        this.eyes.color = new h3d.Vector(0, 1.0, 0);
    }

    public function newLife(): Life {
        var life = new Life(this);
        life.drawable.add(this.fill.getBitmap(), 0);
        life.drawable.add(this.skin.getBitmap(), 1);
        life.drawable.add(this.eyes.getBitmap(), 2);
        return life;
    }
}

