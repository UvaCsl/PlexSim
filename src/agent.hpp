#ifndef AGENT_H_
#define AGENT_H_
#include <stdint.h>
#include <unordered_map>
#include <vector>

#include "adjacency.hpp"
#include "sampler.hpp"

class Agent {
  // abstract base class
  virtual void update() = 0;
};

class Config {
  // general config class
public:
  // list properties
  //
};

class Potts : public Agent {
  // example agent-based system
public:
  double state, beta;
  Adjacency adj;

  Potts();
  Potts(Config &config);
  Potts(adj neighbors);
  void update() override;
};

#endif // AGENT_H_
