This in an entry for this game jam: https://itch.io/jam/-pixel-game-jam-2024

Engine version used: https://godotengine.org/download/archive/4.3-dev6/

The jam theme is: Aqua


# General Concepts:

We are targeting the Playroom category.
Players are attempting to navigate through a desert from oasis to oasis. 
 - Graph from point A to B? Like a FTL level maybe?
They can rest and resupply at oases.
The primary resource driver is water (due to the theme).  
Your goal is to get from point A to B without dying of thirst.
You get to pick when to travel and when to rest.
- Follow cloud cover to reduce water loss?
- Longer you travel without resting, the faster water depletes
- Resting still depletes water
- Traveling during the day burns more water, but is safer from random encounters
- Traveling at night burns less water but has high risk of random encounters
You can search for water in an area (sorta like hunting for meat in Oregon trail).
- Maybe find a cactus, trade health (or not if you have the right tools) for water
- Use dowsing rods to search for water under ground
  - Come up with some interesting way for those to work and find non-water goofy things
Multiplayer elements
- Persistent caravan death sites players can stumble on and resupply from
  - The more people try and fail, the easier for future players?
- Trade and social interactions in town?
- Coop caravans?
- PvP? Can you lie in wait and ambush other players?


# Playroom Features:

To test with Playroom, utilize the upper-right "Remote Debug" -> "Run in Browser" feature to 
get the playroom stuff to activate and have multiplayer running.

## Rooms:
- Every Oasis is zoned as its own named room. Ie, `Oasis1_1`. The digit after the underscore is to allow overflow if the room is full to spawn a new shard for Oasis1.
- After leaving an oasis, the player enters the zone strip between that oasis and the next. That is also its own room (ie, `Zone1_1`).
- Within a room a player will broadcast their movement
- Within a room a player can broadcast speech (maybe simple emoticon wheel?)
- The Playroom devs recommend max of 10-20 players for fast update rates, potentially more for slow update rates.

Pattern for joining room:
	- Player doesn't see any loading screen for rooms, it is all handled in the background transparently
	- Rooms first try to connect to the first shard, but will receive an exception if failed
	- On failure, increment shard id and try next.
	- Join should use the `skipLobby=true` feature
	- Join should use the hardcoded `roomCode=Oasis1_1` feature to join predetermined room layouts.

## Persistence:
- Persistence is a per-room concept so Oasis and Zones will be handled differently (shards technically will also be different)
- Persistence in an Oasis allows players to write things on the ground like Dark Souls?
- Persistence in a Zone tracks the most recent player death and a few dozen footsteps prior to that death.
- Persistence in a Zone tracks what players write on the ground (only one per player)

Pattern for persistence:
	- First insert the player's name + type (ie, `profour_death`) into the `players_notes` or `players_deaths` persistence array. https://docs.joinplayroom.com/components/persistence#insert-data-into-an-array
	- Then insert a persistence key for `profour_death` that contains the death track information or `profour_note` for comments written on ground.
	- Usage will query the `players_notes` and `players_deaths` arrays first to determine all of the player specific keys.
	- Then, once all player keys are known, fetch all of the per key data for display. (if it is a lot, potentially subsample)
	
