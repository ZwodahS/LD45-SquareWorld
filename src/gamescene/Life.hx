
package gamescene;

class Life {

    public var species(default, null): Species;

    public var age(default, null): Int;
    public var drawable: h2d.Layers;

    public function new(sp: Species) {
        this.species = sp;
        this.age = 0;

        this.drawable = new h2d.Layers();
    }
}
