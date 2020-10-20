#include <iostream>
#include <math.h>
#include <complex>
#include <any>
#include <unordered_map>
#include <string>

#include <pybind11/stl.h>
#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include <pybind11/operators.h>

#include "randutils.hpp"
#define FORCE_IMPORT_ARRAY
#include "xtensor/xrandom.hpp"
#include "xtensor-python/pyarray.hpp"
#include "xtensor-blas/xlinalg.hpp"
#include "xtensor/xmath.hpp"
#include "xtensor/xindex_view.hpp"
#include "xtensor/xcomplex.hpp"
#include "xtensor/xstrided_view.hpp"
#include "xtensor/xio.hpp"
#include "xtensor/xarray.hpp"
#include "xtensor/xio.hpp"


#include "robin-map/include/tsl/robin_map.h"
#include "sparse-map/include/tsl/sparse_map.h"
#include "parallel-hashmap/parallel_hashmap/phmap.h"
// #include "Xoshiro-cpp/XoshiroCpp.hpp"
#define PHMAP_USE_ABSL_HASH

#include <ctime>
namespace py = pybind11;
using namespace pybind11::literals;
using namespace std;

// DEFINITIONS
// general model definitions
typedef xt::xarray<double> xarrd;
typedef size_t nodeID_t;
typedef int nodeState_t;
typedef float weight_t;
typedef xt::xarray<nodeState_t> nodeStates;
typedef std::vector<nodeState_t> agentStates_t;

typedef double foena_t;
typedef xt::xarray<foena_t> FOENA;


// sampling binding
typedef xt::xarray<nodeID_t> nodeids_a;
typedef  xt::xarray<nodeID_t> Nodeids;
// typedef std::array<nodeID_t> samples_t;

// Adjacency definition
// typedef phmap::flat_hash_map<nodeID_t, weight_t> Neighbors;
typedef tsl::robin_map<nodeID_t, weight_t> Neighbors;
// typedef tsl::sparse_map<nodeID_t, weight_t> Neighbors;
struct Connection{
    Neighbors neighbors;
};


// typedef boost::unordered_map<nodeID_t, Connection> Connections;
// typedef phmap::flat_hash_map<nodeID_t, Connection> Connections;
typedef tsl::robin_map<nodeID_t, Connection> Connections;
// typedef phmap::parallel_flat_hash_map<nodeID_t, Connection> Connections;
// typedef tsl::sparse_map<nodeID_t, Connection> Connections;
double PI =xt::numeric_constants<double>::PI ;

// typedef phmap::flat_hash_map<vector<size_t>, double> TMP;
typedef std::map<vector<size_t>, double> TMP;
