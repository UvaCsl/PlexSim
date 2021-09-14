#ifndef SAMPLER_H_
#define SAMPLER_H_

#include <stdint.h>
class Sampler {
  // holds rng stuff
public:
  Sampler();
  Sampler(size_t seed);
  double rand();
  void set_seed(size_t seed);

private:
  size_t seed;
};

#endif // SAMPLER_H_
