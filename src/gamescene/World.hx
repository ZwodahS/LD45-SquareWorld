
package gamescene;

import haxe.ds.Vector;
import common.Point2i;

class World {
    public var cells(default, null): Vector<Vector<Grid>>;

    var worldLayer: h2d.Layers;
    public var lifeList: List<Life>;

    public function new(worldLayer: h2d.Layers, width: Int, height: Int, assets: common.Assets) {
        this.worldLayer = worldLayer;
        this.lifeList = new List<Life>();
        this.cells = new Vector<Vector<Grid>>(width);
        for (x in 0...width) {
            this.cells[x] = new Vector<Grid>(height);
            for (y in 0...height) {
                var grid = new Grid(assets);
                grid.x = x;
                grid.y = y;
                this.cells[x][y] = grid;
            }
        }
    }

    public function addLife(life: Life): Bool {
        var cell = this.cells[life.x][life.y];
        if (life.type == "animal") {
            if (cell.animal != null) {
                return false;
            }
            cell.animal = life;
        } else if (life.type == "plant") {
            if (cell.plant != null) {
                return false;
            }
            cell.plant = life;
        } else {
            return false;
        }
        this.worldLayer.add(life.drawable, 0);
        this.lifeList.add(life);
        return true;
    }

    public function moveLife(life: Life, pos: Point2i): Bool{
        if (!this.inBound(pos)) return false;
        var cell = this.cells[pos.x][pos.y];
        if (life.type == "animal") {
            if (cell.animal != null) {
                return false;
            }
            cell.animal = life;
        } else if (life.type == "plant") {
            if (cell.plant != null) {
                return false;
            }
            cell.plant = life;
        } else {
            return false;
        }

        var currentCell = this.cells[life.x][life.y];
        if (life.type == "animal") {
            if (currentCell.animal == life) {
                currentCell.animal = null;
            }
        } else {
            if (currentCell.plant == life) {
                currentCell.plant = null;
            }
        }

        life.x = pos.x;
        life.y = pos.y;
        return true;
    }

    public function removeLife(life: Life) {
        if (this.inBound([life.x, life.y])) {
            var cell = this.cells[life.x][life.y];
            if (life.type == "animal") {
                cell.animal = null;
            }
            else if (life.type == "plant") {
                cell.plant = null;
            }
        }
        this.lifeList.remove(life);
        this.worldLayer.removeChild(life.drawable);
    }

    public function inBound(pos: Point2i): Bool {
        return pos.x >= 0 && pos.x < this.cells.length && pos.y >= 0 && pos.y < this.cells[0].length;
    }

    public function addNutrients(pos: Point2i, amount:Int): Bool {
        var cell = this.inBound(pos) ? this.cells[pos.x][pos.y]: null;
        if (cell == null) return false;

        cell.nutrients += amount;
        return true;
    }
    public function drainNutrients(pos: Point2i, amount: Int): Int {
        var cell = this.inBound(pos) ? this.cells[pos.x][pos.y] : null;
        if (cell == null) return 0;

        var drain = hxd.Math.imin(cell.nutrients, amount);
        cell.nutrients -= drain;
        return drain;
    }

    public function drainFood(pos: Point2i, amount: Int): Int {
        var cell = this.inBound(pos) ? this.cells[pos.x][pos.y] : null;
        if (cell == null) return 0;

        var drain = hxd.Math.imin(cell.food, amount);
        cell.food -= drain;
        return drain;
    }

    public function addFood(pos: Point2i, amount: Int): Bool {
        var cell = this.inBound(pos) ? this.cells[pos.x][pos.y]: null;
        if (cell == null) return false;

        cell.food += amount;
        return true;
    }
}
