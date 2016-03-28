#include "neswrap.h"

#define NUM_ACTION_REPEATS 10

long get_random_action(long max) {

  unsigned long
    // max <= RAND_MAX < ULONG_MAX, so this is okay.
    num_bins = (unsigned long) max + 1,
    num_rand = (unsigned long) RAND_MAX + 1,
    bin_size = num_rand / num_bins,
    defect   = num_rand % num_bins;

  long x;
  do {
   x = random();
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned long)x);

  // Truncated division is intentional
  return x/bin_size;
}

int main(int argc, char *argv[]) {

	if (argc != 2) {
		printf("Must specify path to ROM.");
		return 1;
	}
	const char *rom_file = argv[1];

	NESInterface *nes = nes_new(rom_file);

	// Test dimensions.
	int w = nes_getScreenWidth(nes);
	int h = nes_getScreenHeight(nes);
	printf("Screen dimensions: %i, %i\n", w, h);

	// Always the same for NES games...
	int num_actions = nes_numLegalActions(nes);
	int actions[num_actions];
	memset(actions, 0, num_actions * sizeof(int));

	// Returns the valid actions for a game
	nes_legalActions(nes, actions, num_actions);

	int remaining_lives = 0;

	while (true) {

		// Check to see if the game is playable...
		if (nes_isGameOver(nes)) {

			printf("Game Over: resetting...\n");
			nes_resetGame(nes);
		}

		// Get the game up and running and perform random actions.
		int action = get_random_action(14);

		// Repeat each action.
		for (int i = 0; i < NUM_ACTION_REPEATS; i++) {
			int reward = nes_act(nes, action);
			if (reward != 0) {
				printf("Reward: %i\n", reward);
			}
		}

		// Returns the number of remaining lives for a game
		int new_remaining_lives = nes_livesRemaining(nes);
		if (new_remaining_lives != remaining_lives) {
			printf("Lives: %i\n", new_remaining_lives);
			remaining_lives = new_remaining_lives;
		}

		// Make an observation.
		int size = w * h;
		uint8_t obs[size];
		nes_fillObs(nes, obs, size);
	}

	// Resets the game.
	nes_resetGame(nes);

	// Test the garbage collector.
	nes_gc(nes);

	return 0;
}

/*
// Converts the palette values to RGB.
// The shape of the rgb array should be 3 x obs.shape.
void nes_fillRgbFromPalette(uint8_t *rgb, const uint8_t *obs,
                                   size_t rgb_size, size_t obs_size);

// Indicates whether the game ended.
// Call resetGame to restart the game.
//
// Returning of bool instead of int is important.
// The bool is converted to lua bool by FFI.
bool nes_isGameOver(const NESInterface *nes);

// NES save state
void nes_saveState(NESInterface *nes);

// NES load state
bool nes_loadState(NESInterface *nes);

// Fills the obs with raw palette values.
//
// Currently, the palette values are even numbers from 0 to 255.
// So there are only 128 distinct values.
void nes_fillObs(const NESInterface *nes, uint8_t *obs, size_t obs_size);

// Fills the given array with the content of the RAM.
// The obs_size should be 128.
// NOT IMPLEMENTED
//void nes_fillRamObs(const NESInterface *nes, uint8_t *obs, size_t obs_size);

// Returns the number of legal actions
// NOT IMPLEMENTED
//int nes_numLegalActions(NESInterface *nes);

// Used by api to create a string of correct size.
int nes_getSnapshotLength(const NESInterface *nes);

// Save the current state into a snapshot
void nes_saveSnapshot(const NESInterface *nes, uint8_t *data, size_t length);

// Load a particular snapshot into the emulator
void nes_restoreSnapshot(NESInterface *nes, const uint8_t *snapshot,
                         size_t size);
 */


