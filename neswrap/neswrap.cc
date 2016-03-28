#include "neswrap.h"

#include <stdexcept>
#include <cassert>
#include <algorithm>

void nes_fillRgbFromPalette(uint8_t *rgb, const uint8_t *obs, size_t rgb_size,
                            size_t obs_size) {
  assert(obs_size >= 0);
  assert(rgb_size == 3 * obs_size);

  const int r_offset = 0ul;
  const int g_offset = obs_size;
  const int b_offset = 2ul * obs_size;

  for (int index = 0ul; index < obs_size; ++index) {
    uint8_t r, g, b;
    NESInterface::getRGB(obs[index], r, g, b);

    rgb[r_offset + index] = r;
    rgb[g_offset + index] = g;
    rgb[b_offset + index] = b;
  }
}

NESInterface *nes_new(const char *rom_file) {
	return new NESInterface(rom_file);
}

void nes_gc(NESInterface *nes) { delete nes; }

double nes_act(NESInterface *nes, int action) {

  assert(action >= static_cast<int>(nes::NOOP) &&
         action <= static_cast<int>(nes::B_DOWN));
  return nes->act(static_cast<nes::Action>(action));
}

int nes_getScreenWidth(const NESInterface *nes) {
  return nes->getScreenWidth();
}

int nes_getScreenHeight(const NESInterface *nes) {
  return nes->getScreenHeight();
}

bool nes_isGameOver(NESInterface *nes) { return nes->gameOver(); }

void nes_resetGame(NESInterface *nes) {
  nes->resetGame();
  assert(!nes->gameOver());
}

bool nes_loadState(NESInterface *nes) { return nes->loadState(); }

void nes_saveState(NESInterface *nes) { nes->saveState(); }

void nes_fillObs(const NESInterface *nes, uint8_t *obs, size_t obs_size) {

	// Copy the contents of the screen (XBuf) to obs.
	const uint8_t *screen = nes->getScreen();
	int width = nes->getScreenWidth();
	int height = nes->getScreenHeight();
	assert(obs_size == height * width);

	std::copy(screen, screen + obs_size, obs);
}

int nes_numLegalActions(NESInterface *nes) {
	return nes->getNumLegalActions();
}

void nes_legalActions(NESInterface *nes, int *actions, size_t actions_size) {

	nes::ActionVect actions_vec = nes->getLegalActionSet();
	assert(actions_vec.size() == actions_size);
	for (int i = 0; i < actions_size; i++) {
		actions[i] = actions_vec[i];
	}
}

int nes_livesRemaining(const NESInterface *nes) {
	return nes->lives();
}

int nes_getSnapshotLength(const NESInterface *nes) {
  return static_cast<int>(nes->getSnapshot().size());
}

void nes_saveSnapshot(const NESInterface *nes, uint8_t *data,
                      size_t length) {
  std::string result = nes->getSnapshot();

  assert(length >= result.size() && length > 0);

  if (length < result.size())
    data = NULL;
  else
    result.copy(reinterpret_cast<char *>(data), length);
}

void nes_restoreSnapshot(NESInterface *nes, const uint8_t *snapshot,
                         size_t size) {
  assert(size > 0);

  std::string snapshotStr(reinterpret_cast<char const *>(snapshot), size);
  nes->restoreSnapshot(snapshotStr);
}

