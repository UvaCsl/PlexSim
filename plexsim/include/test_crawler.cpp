
#include <algorithm>
#include <cstddef>
#include <iostream>
#include <set>
#include <stdio.h>

#include "../plexsim/include/crawler.hpp"
#include <unordered_set>

int main() {

  // std::set<int> a = {1, 1, 1};
  // std::set<int> b = {1, 2, 3};
  // std::set<int> c;
  // std::set<int> d;

  size_t idx = 1;
  size_t jdx = 2;

  auto node = ColorNode(1, 1);
  auto other = ColorNode(2, 2);
  auto another = ColorNode(3, 3);
  auto that = ColorNode(4, 4);
  auto five = ColorNode(5, 5);

  EdgeColor aa = {node, other};
  EdgeColor bb = {other, that};
  EdgeColor cc = {that, five};
  EdgeColor dd = {other, node};
  EdgeColor raa = {other, node};

  std::set<EdgeColor> a = {bb, cc, aa, dd};
  std::set<EdgeColor> b = {aa, raa, aa};

  auto it = b.begin();

  // printf("%d\n", b.size());
  // while (it != b.end()) {
  //   printf("%d %d ", it->current.name, it->other.name);
  //   printf("%f %f\n", it->current.state, it->other.state);
  //   it++;
  // }

  // it = a.begin();
  // while (it != a.end()) {
  //   printf("%d %d ", it->current.name, it->other.name);
  //   printf("%f %f\n", it->current.state, it->other.state);
  //   it++;
  // }

  // intersection
  std::set<EdgeColor> c, d;
  printf("%ld\n", c.size());
  std::set_intersection(a.begin(), a.end(), a.begin(), a.end(),
                        std::inserter(c, c.begin()));

  // c.resize(jt - c.begin());
  printf("%ld\n", c.size());

  auto F = std::set<EdgeColor>(c.begin(), c.end());
  printf("%ld\n", F.size());

  for (auto e : F) {
    printf("%ld\t%ld\n", e.current.name, e.other.name);
  }

  // union
  // it = set_union(a.begin(), a.end(), b.begin(), b.end(), d.begin());
  // d.resize(it - d.begin());

  // std::set<EdgeColor>::iterator it = d.begin();
  // std::cout << "Union" << std::endl;
  // std::cout << d.size() << std::endl;

  // while (it != d.end()) {
  //   it->print();
  //   it++;
  // }
}
