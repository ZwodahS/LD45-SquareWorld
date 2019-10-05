
package gamescene;

class Sun extends h2d.Layers{

    var width: Float;
    var height: Float;
    var moveSpeed:Float = 100;

    public function new(width: Float, height: Float, assets: common.Assets) {
        super();
        this.width = width;
        this.height = height;

        var sun = assets.getAsset("sun").getBitmap();
        sun.color = new h3d.Vector(1.0, 1.0, 0.0, 0.3);
        this.add(sun, 0);
    }

    public function update(dt: Float) {
        this.x += dt * this.moveSpeed;
    }
}
