
package gamescene;

class Grid {

    public var drawable: h2d.Layers;
    public var x(default, set): Int;
    public var y(default, set): Int;

    var nutrientsBitmap: h2d.Bitmap;

    public var nutrients(default, set): Int = 0;
    public var food(default, set): Int = 0;

    public var plant: Life = null;
    public var animal: Life = null;

    var assets: common.Assets;

    var currentFoodIndex: Int = -2;
    var currentNutrientsIndex: Int = -2;

    var foodAnim: h2d.Anim = null;
    var nutrientsAnim: h2d.Anim = null;

    public function new(assets: common.Assets) {
        this.drawable = new h2d.Layers();
        this.drawable.add(new h2d.Bitmap(h2d.Tile.fromColor(0x241C07, Constants.GridSize, Constants.GridSize)), 0);

        this.foodAnim = new h2d.Anim(assets.getAsset("food").getTiles(), 0);
        this.drawable.add(this.foodAnim, 1);
        this.nutrientsAnim = new h2d.Anim(assets.getAsset("nutrient").getTiles(), 0);
        this.nutrientsAnim.color = h3d.Vector.fromColor(0xFFFFFF55);
        this.drawable.add(this.nutrientsAnim, 1);

        this.nutrients = Math.floor(Math.random() * 80);
        this.food = hxd.Math.imax(Math.floor(Math.random() * 50) - 48, 0) * 10;
        updateBitmap();
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
        this.updateBitmap();
        return this.nutrients;
    }

    public function set_food(food: Int): Int {
        this.food = food;
        this.updateBitmap();
        return this.food;
    }

    function updateBitmap() {
        var newFoodIndex = Math.ceil(hxd.Math.clamp(this.food/100, 0, 3)) - 1;
        var newNutrientIndex = Math.ceil(hxd.Math.clamp(this.nutrients/70, 0, 3)) - 1;
        if (newFoodIndex != this.currentFoodIndex) {
            this.currentFoodIndex = newFoodIndex;
            if (this.currentFoodIndex == -1 ){
                this.foodAnim.visible = false;
            } else {
                this.foodAnim.currentFrame = this.currentFoodIndex;
                this.foodAnim.visible = true;
            }
        }

        this.nutrientsAnim.color.a = hxd.Math.clamp(this.nutrients/200, 0.0, 0.8);

        if (newNutrientIndex != this.currentNutrientsIndex) {
            this.currentNutrientsIndex = newNutrientIndex;
            if (this.currentNutrientsIndex == -1) {
                this.nutrientsAnim.visible = false;
            } else {
                this.nutrientsAnim.visible = true;
                this.nutrientsAnim.currentFrame = this.currentNutrientsIndex;
            }
        }
    }
}
