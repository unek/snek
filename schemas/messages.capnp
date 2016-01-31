@0xf7286079653eb8fd;

using import "snek.capnp".Snek;
using Common = import "common.capnp";

struct Message {
	enum MessageType {
		tick @0;
		hello @1;
		chat @2;

		addSnek @3;
		removeSnek @4;

		respawn @5;
		turn @6;
		resize @7;
		die @8;
		stop @9;
	}
	# message header
	type @0 :MessageType;
	compressed @1 :Bool;
	# actual encoded message
	message @2 :Data;

	struct Hello {
		version @0 :UInt16;
		nickname @1 :Text;
	}

	struct Respawn {
		id @0 :UInt16;
	}

	struct Turn {
		id @0 :UInt16;
		direction @1 :UInt8;
	}

	struct Resize {
		id @0 :UInt16;
		size @1 :UInt16;
	}

	struct Die {
		id @0 :UInt16;
	}

	struct Stop {
		id @0 :UInt16;
	}

	struct Chat {
		struct MessagePart {
			color @0 :Common.Color;
			text @1 :Text;

			formatting :group {
				bold @2 :Bool;
				underline @3 :Bool;
				italic @4 :Bool;
				fontSize @5 :UInt8;
			}
		}

		message @0 :List(MessagePart);
	}
}