
package gamescene;

class Grid {

    public var drawable: h2d.Layers;
    public var x(default, set): Int;
    public var y(default, set): Int;

    var nutrientsBitmap: h2d.Bitmap;

    public var nutrients(default, set): Int;

    public var plant: Life = null;
    public var animal: Life = null;

    public function new() {
        this.drawable = new h2d.Layers();
        this.drawable.add(new h2d.Bitmap(h2d.Tile.fromColor(0x241C07, Constants.GridSize, Constants.GridSize)), 0);
        this.nutrientsBitmap = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFF55, Constants.GridSize, Constants.GridSize));
        this.drawable.add(nutrientsBitmap, 1);
        this.nutrients = Math.floor(Math.random() * 80);
        updateNutrientsBitmap();
    }

    public function set_x(x: Int): Int {
        this.x = x;
        this.drawable.x = x * Constants.GridSize;
        return this.x;
    }

    public function set_y(y: Int): Int {
        this.y = y;
        this.drawable.y = y * Constants.GridSize;
        return this.y;
    }

    public function set_nutrients(nutrients: Int): Int {
        this.nutrients = nutrients;
        this.updateNutrientsBitmap();
        return this.nutrients;
    }

    function updateNutrientsBitmap() {
        this.nutrientsBitmap.color.w = Math.min(this.nutrients / 300, 0.5);
    }
}
