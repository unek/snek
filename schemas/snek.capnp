@0x8247c293dcbde234;

struct Snek {
	id @0 :UInt16;
	name @1 :Text;

	direction @2 :UInt8;
	nextDirection @3 :UInt8;
	maxLength @4 :UInt16;

	dead @5 :Bool;
	stopped @6 :Bool;

	speed @7 :UInt8;
	lastMove @8 :UInt8;

	blocks @9 :List(Block);

	color @10 :Color;

	struct Color {
		r @0: UInt8;
		g @1: UInt8;
		b @2: UInt8;
	}

	struct Block {
		x @0 :Int16;
		y @1 :Int16;
	}
}