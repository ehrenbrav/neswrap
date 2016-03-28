#ifndef NESWRAP_H
#define NESWRAP_H

#include <fceux/nes_interface.hpp>

typedef nes::NESInterface NESInterface;

extern "C" {
#include "neswrap.inl"
}

#endif  // NESWRAP_H
