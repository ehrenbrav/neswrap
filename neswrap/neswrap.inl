// explicit declare
typedef unsigned char uint8_t;

// Converts the palette values to RGB.
// The shape of the rgb array should be 3 x obs.shape.
void nes_fillRgbFromPalette(uint8_t *rgb, const uint8_t *obs,
                                   size_t rgb_size, size_t obs_size);

// Initializes the environment.
NESInterface *nes_new(const char *rom_file);

// Deletes the pointer.
void nes_gc(NESInterface *nes);

// Applies the action and returns the obtained reward.
double nes_act(NESInterface *nes, int action);

// Returns the screen width.
int nes_getScreenWidth(const NESInterface *nes);

// Returns the screen height.
int nes_getScreenHeight(const NESInterface *nes);

// Returns the current score.
int nes_getCurrentScore(const NESInterface *nes);

// Indicates whether the game ended.
// Call resetGame to restart the game.
//
// Returning of bool instead of int is important.
// The bool is converted to lua bool by FFI.
bool nes_isGameOver(NESInterface *nes);

// Resets the game.
void nes_resetGame(NESInterface *nes);

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
void nes_fillRamObs(const NESInterface *nes, uint8_t *obs, size_t obs_size);

// Returns the number of legal actions
int nes_numLegalActions(NESInterface *nes);

// Returns the valid actions for a game
void nes_legalActions(NESInterface *nes, int *actions, size_t size);

// Returns the number of remaining lives for a game
int nes_livesRemaining(const NESInterface *nes);

// Used by api to create a string of correct size.
int nes_getSnapshotLength(const NESInterface *nes);

// Save the current state into a snapshot
void nes_saveSnapshot(const NESInterface *nes, uint8_t *data, size_t length);

// Load a particular snapshot into the emulator
void nes_restoreSnapshot(NESInterface *nes, const uint8_t *snapshot,
                         size_t size);