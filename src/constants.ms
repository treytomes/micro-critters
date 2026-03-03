// Every frame, each entity will receive an amount of energy equal to (elapsed time * entity constitution * this value).
//
// Tweak this until it makes sense; it should set the pace for the entire game.
//
CONSTITUTION_ENERGY_FACTOR = 50


// Measured in seconds; if an entity can get bored, they'll wait this long to do so.
// This might be the time to enact random behaviors, or a "wander" behavior.
//
ENTITY_BORED_TIME = 3


// Assets will be loaded from this path.
//
ASSET_ROOT = "/usr/assets/"


// Pulled from /sys/lib/tc; move all these constants into globals.
for kv in locals
	if kv.key[0] != "_" then globals[kv.key] = @kv.value		
end for