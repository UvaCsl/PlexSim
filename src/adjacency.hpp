#ifndef ADJACENCY_H_
#define ADJACENCY_H_

#include "agent.hpp"
typedef std::unordered_map<Agent, double> adj;
class Adjacency {
  /* Holds any relations among agents.
   *  */
private:
  adj neighbors;

public:
  void add_agent(Agent agent);
  void remove_agent(Agent agent);
};

#endif // ADJACENCY_H_
