# distutils: language=c++
# __author__ = 'Casper van Elteren'
cimport cython

import numpy as np
cimport numpy as np
import networkx as nx, functools, time
from tqdm import tqdm
import copy

from cython.parallel cimport parallel, prange
from cython.operator cimport dereference, preincrement
from libc.stdlib cimport malloc, free
# from libc.stdlib cimport rand
from libc.string cimport strcmp
from libc.stdio cimport printf
from libcpp.vector cimport vector
from libcpp.map cimport map
from libcpp.unordered_map cimport unordered_map
from libc.math cimport lround, abs
# cdef extern from "limits.h":
#     int INT_MAX
#     int RAND_MAX

__VERSION__ = 1.2 # added version number
# SEED SETUP
from posix.time cimport clock_gettime,\
timespec, CLOCK_REALTIME

# from sampler cimport Sampler # mersenne sampler
cdef class Model: # see pxd
    def __init__(self,\
                 **kwargs,\
                 ):
        '''
        General class for the models
        It defines the expected methods for the model; this can be expanded
        to suite your personal needs but the methods defined here need are relied on
        by the rest of the package.

        It translates the networkx graph into c++ unordered_map map for speed

        kwargs should at least have:
        :graph: a networkx graph

        optional:
            :agentStates: the states that the agents can assume [default = [0,1]]
            :updateType: how to sample the state space (default async)
            :nudgeType: the type of nudge used (default: constant)
            :memorySize: use memory dynamics (default 0)
        '''
        # use current time as seed for rng
        cdef timespec ts
        clock_gettime(CLOCK_REALTIME, &ts)
        cdef unsigned int seed = ts.tv_sec
        # define rng sampler
        self.dist = uniform_real_distribution[double](0.0, 1.0)
        self.seed = seed
        self.gen  = mt19937(self.seed)

        # create adj list
        self.construct(kwargs.get('graph'), kwargs.get('agentStates', [-1, 1]))

        # create properties
        self.nudgeType  = copy.copy(kwargs.get('nudgeType', 'constant'))
        self.updateType = kwargs.get('updateType', 'async')

        # self.memory = np.ones((memorySize, self._nNodes), dtype = long) * np.NaN   # note keep the memory first not in state space, i.e start without any form memory

        # create memory
        self.memorySize   = kwargs.get('memorySize', 0)
        self._memory      = np.random.choice(self.agentStates, size = (self.memorySize, self._nNodes))
        # TODO: remove
        tmp =  kwargs.get('kwargs', {})
        self.nudges = tmp.get('nudges', {})

    cpdef void construct(self, object graph, list agentStates):
        """
        Constructs adj matrix using structs

        intput:
            :nx.Graph or nx.DiGraph: graph
        """
        # check if graph has weights or states assigned and or nudges
        # note does not check all combinations
        # input validation / construct adj lists
        # defaults
        DEFAULTWEIGHT = 1.
        DEFAULTNUDGE  = 0.
        # DEFAULTSTATE  = random # don't use; just for clarity
        # enforce strings
        version =  getattr(graph, '__version__', __VERSION__)
        graph = nx.relabel_nodes(graph, {node : str(node) for node in graph.nodes()})
        graph.__version__ = version
        # forward declaration and init
        cdef:
            dict mapping = {} # made nodelabe to internal
            dict rmapping= {} # reverse
            # str delim = '\t'
            np.ndarray states = np.zeros(graph.number_of_nodes(), int, 'C')
            int counter = 0
            # double[::1] nudges = np.zeros(graph.number_of_nodes(), dtype = float)
            unordered_map[long, double] nudges      
            # np.ndarray nudges = np.zeros(graph.number_of_nodes(), dtype = float)
            unordered_map[long, Connection] adj # see .pxd



        # new data format
        if getattr(graph, '__version__',  __VERSION__ ) > 1.0:
            # generate graph in json format
            nodelink = nx.node_link_data(graph)
            for nodeidx, node in enumerate(nodelink['nodes']):
                id                = node.get('id')
                mapping[id]       = nodeidx
                rmapping[nodeidx] = id
                states[nodeidx]   = <long>   node.get('state', np.random.choice(agentStates))
                nudges[nodeidx]   = <double> node.get('nudge', DEFAULTNUDGE)
            directed  = nodelink.get('directed')
            for link in nodelink['links']:
                source = mapping[link.get('source')]
                target = mapping[link.get('target')]
                weight = <double> link.get('weight', DEFAULTWEIGHT)
                # reverse direction for inputs
                if directed:
                    # get link as input
                    adj[target].neighbors.push_back(source)
                    adj[target].weights.push_back(weight)
                else:
                    # add neighbors
                    adj[source].neighbors.push_back(target)
                    adj[target].neighbors.push_back(source)

                    # add weights
                    adj[source].weights.push_back(weight)
                    adj[target].weights.push_back(weight)
        # version <= 1.0
        else:
            from ast import literal_eval
            for line in nx.generate_multiline_adjlist(graph, ','):
                add = False # tmp for not overwriting doubles
                # input validation
                lineData = []
                # if second is not dict then it must be source
                for prop in line.split(','):
                    try:
                        i = literal_eval(prop) # throws error if only string
                        lineData.append(i)
                    except:
                        lineData.append(prop) # for strings
                node, info = lineData
                # check properties, assign defaults
                if 'state' not in graph.nodes[node]:
                    idx = np.random.choice(agentStates)
                    graph.nodes[node]['state'] = idx
                if 'nudge' not in graph.nodes[node]:
                    graph.nodes[node]['nudge'] =  DEFAULTNUDGE

                # if not dict then it is a source
                if isinstance(info, dict) is False:
                    # add node to seen
                    if node not in mapping:
                        # append to stack
                        counter             = len(mapping)
                        mapping[node]       = counter
                        rmapping[counter]   = node

                    # set source
                    source   = node
                    sourceID = mapping[node]
                    states[sourceID] = <long> graph.nodes[node]['state']
                    nudges[sourceID] = <double> graph.nodes[node]['nudge']
                # check neighbors
                else:
                    if 'weight' not in info:
                        graph[source][node]['weight'] = DEFAULTWEIGHT
                    if node not in mapping:
                        counter           = len(mapping)
                        mapping[node]     = counter
                        rmapping[counter] = node

                    # check if it has a reverse edge
                    if graph.has_edge(node, source):
                        sincID = mapping[node]
                        weight = graph[node][source]['weight']
                        # check if t he node is already in stack
                        if sourceID in set(adj[sincID]) :
                            add = True
                        # not found so we should add
                        else:
                            add = True
                    # add source > node
                    sincID = <long> mapping[node]
                    adj[sourceID].neighbors.push_back(<long> mapping[node])
                    adj[sourceID].weights.push_back(<double> graph[source][node]['weight'])
                    # add reverse
                    if add:
                        adj[sincID].neighbors.push_back( <long> sourceID)
                        adj[sincID].weights.push_back( <double> graph[node][source]['weight'])

        # public and python accessible
        self.graph       = graph
        self.mapping     = mapping
        self.rmapping    = rmapping
        self._adj        = adj

        self._agentStates = np.asarray(agentStates, dtype = int).copy()

        self._nudges     = nudges #nudges.copy()
        self._nStates    = len(agentStates)


        #private
        # note nodeids will be shuffled and cannot be trusted for mapping
        # use mapping to get the correct state for the nodes

        _nodeids        = np.arange(graph.number_of_nodes(), dtype = long)
        np.random.shuffle(_nodeids) # prevent initial scan-lines in grid
        self._nodeids   = _nodeids.copy()
        self._states    = states.copy()

        # self._newstates = states.copy()
        self._nNodes    = graph.number_of_nodes()

    # cdef long[::1]  _updateState(self, long[::1] nodesToUpdate) :
    cdef long[::1]  _updateState(self, long[::1] nodesToUpdate) nogil:
        return self._nodeids
    #
    #
    cpdef long[::1] updateState(self, long[::1] nodesToUpdate):
        return self._updateState(nodesToUpdate)


    cdef double rand(self) nogil:
        return self.dist(self.gen)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(True)
    @cython.initializedcheck(False)
    @cython.overflowcheck(False)
    cpdef long[:, ::1] sampleNodes(self, int nSamples):
        return self._sampleNodes(nSamples)
    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(True)
    @cython.initializedcheck(False)
    @cython.overflowcheck(False)
    cdef long[:, ::1] _sampleNodes(self, int  nSamples) nogil:
    # cdef long [:, ::1] sampleNodes(self, long  nSamples):
        """
        Shuffles nodeids only when the current sample is larger
        than the shuffled array
        N.B. nodeids are mutable
        """
        # check the amount of samples to get
        cdef int sampleSize
        cdef long[:, ::1] tmp
        cdef int x
        if self._updateType == 'single':
            sampleSize = self._sampleSize
        elif self._updateType == 'serial':
            for x in range(self._nNodes):
                tmp[x] = self._nodeids[x]
            return tmp
        else:
            sampleSize = self._sampleSize
        cdef:
            # TODO replace this with a nogil version
            # long _samples[nSamples][sampleSize]
            long [:, ::1] samples
            # long sample
            long start
            long i, j, k
            long samplei

            # vector[vector[int][sampleSize]] samples

        # replace with nogil variant
        with gil:
            samples = np.zeros((nSamples, sampleSize), dtype = long,\
                                order = 'C')
        for samplei in range(nSamples):
            # shuffle if the current tracker is larger than the array
            start  = (samplei * sampleSize) % self._nNodes
            if (start + sampleSize >= self._nNodes or sampleSize == 1):
                for i in range(self._nNodes):
                    # shuffle the array without replacement
                    j                = lround(self.rand() * (self._nNodes - 1))
                    k                = self._nodeids[j]
                    self._nodeids[j] = self._nodeids[i]
                    self._nodeids[i] = k
                    # enforce atleast one shuffle in single updates; otherwise same picked
                    if sampleSize == 1 : break
            # assign the samples; will be sorted in case of serial
            for j in range(sampleSize):
                samples[samplei][j]    = self._nodeids[j]
        return samples
    cpdef void reset(self):
        self.states = np.random.choice(\
                self.agentStates, size = self._nNodes)


    def removeAllNudges(self):
        """
        Sets all nudges to zero
        """
        self.nudges[:] = 0

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.nonecheck(False)
    @cython.cdivision(True)
    @cython.initializedcheck(False)
    @cython.overflowcheck(False)
    cpdef np.ndarray simulate(self, int  samples):
        cdef:
            long[:, ::1] results = np.zeros((samples, self._nNodes), long)
            # int sampleSize = 1 if self._updateType == 'single' else self._nNodes
            long[:, ::1] r = self.sampleNodes(samples)
            # vector[vector[int][sampleSize]] r = self.sampleNodes(samples)
            int i

        results[0] = self._states
        for i in range(samples):
            results.base[i] = self.updateState(r[i])
        return results.base # convert back to normal array

    # TODO: make class pickable
    # hence the wrappers
    @property
    def memorySize(self): return self._memorySize
    @memorySize.setter
    def memorySize(self, value):
        self._memorySize = value

    @property
    def memory(self): return self._memory
    @memory.setter
    def memory(self, value):
        if isinstance(value, np.ndarray):
            self._memory = value
    @property
    def sampleSize(self): return self._sampleSize

    @property
    def agentStates(self): return list(self._agentStates) # warning has no setter!
    @property
    def adj(self)       : return self._adj
    @property
    def states(self)    : return self._states
    @property
    def updateType(self): return self._updateType
    @property
    def nudgeType(self) : return self._nudgeType
    @property #return mem view of states
    def states(self)    : return self._states
    @property
    def nodeids(self)   : return self._nodeids
    @property
    def nudges(self)    : return self._nudges
    @property
    def nNodes(self)    : return self._nNodes
    @property
    def nStates(self)   : return self._nStates
    @property
    def nodeids(self)   : return self._nodeids
    @property
    def seed(self)      : return self._seed

    @memorySize.setter
    def memorySize(self, value):
        self._memorySize = value

    @seed.setter
    def seed(self, value):
        if isinstance(value, int) and value >= 0:
            self._seed = value
            self.gen   = mt19937(self.seed)
        else:
            print("Value is not unsigned long")


    # TODO: reset all after new?
    @nudges.setter
    def nudges(self, vals):
        """
        Set nudge value based on dict using the node labels
        """
        self._nudges.clear()
        if isinstance(vals, dict):
            for k, v in vals.items():
                # assert string
                idx = self.mapping[str(k)]
                self._nudges[idx] = v
        elif isinstance(vals, np.ndarray):
            assert len(vals) == self.nNodes
            for node in range(self.nNodes):
                if vals[node]:
                    self._nudges[node] = vals[node]
        elif isinstance(vals, cython.view.memoryview):
            assert len(vals) == self.nNodes
            for node in range(self.nNodes):
                if vals.base[node]:
                    self._nudges[node] = vals.base[node]
    @updateType.setter
    def updateType(self, value):
        """
        Input validation of the update of the model
        Options:
            - sync  : synchronous; update independently from t > t + 1
            - async : asynchronous; update n Nodes but with mutation possible
            - single: update 1 node random
            - serial: like crt scan
            - [float]: async but only x percentage of the total system
        """
        assert value in 'sync async single serial' or float(value)

        self._updateType = value
        # allow for mutation if async else independent updates
        # self._newstates = self._states.copy()
        if value == 'async' or value == 'sync':
            self._sampleSize = self._nNodes
            #for node in range(self.nNodes):
             #   self._newstates[node] = self._states[node]
        # scan lines
        if value == 'serial':
            self._sampleSize = self._nNodes
            self._nodeids = np.sort(self._nodeids) # enforce  for sampler
        # percentage
        try:
            tmp = float(value)
            assert tmp > 0, "Don't think you want to sample 0 nodes"
            self._sampleSize = np.max((<long>(tmp * self._nNodes), 1))
        except Exception as e:
            pass
        # single
        if value == 'single':
            self._sampleSize = 1

    @nudgeType.setter
    def nudgeType(self, value):
        assert value in 'constant pulse'
        self._nudgeType = value

    @states.setter # TODO: expand
    def states(self, value):
        cdef int idx
        if isinstance(value, int):
            self._states   [:] = value
        # TODO: change this to iterable check
        elif isinstance(value, np.ndarray) or isinstance(value, list):
            assert len(value) == self.nNodes
            value = np.asarray(value) # enforce
            self._states    = value
        elif isinstance(value, dict):
            for k, v in value.items():
                idx = self.mapping[k]
                self._states[idx] = v

    cdef void _hebbianUpdate(self):
        """
        Hebbian learning rule that will strengthen similar
        connections and weaken dissimilar connections

        """

        # TODO: add learning rate delta
        # TODO: use hamiltonian function -> how to make general
        cdef:
            int nodeI, nodeJ
            int neighbors, neighbor
            int stateI, stateJ
            double weightI, weightJ # weights
            double Z # normalization constant
            double tmp

            vector[double] hebbianWeights
        # get neighbors
        for nodeI in range(self._nNodes):
            # update connectivity weight
            stateI = self._states[nodeI]
            neighbors = self._adj[nodeI].neighbors.size()
            # init values
            Z = 0
            
            hebbianWeights = range(neighbors) 
            # construct weight vector
            for nodeJ in range(neighbors):
                neighbor = self._adj[nodeI].neighbors[nodeJ]
                stateJ = self._states[neighbor]
                weightJ = self._adj[nodeI].weights[nodeJ]
                tmp = 1 + .1 * weightJ * self._learningFunction(stateI, stateJ)
                hebbianWeights[nodeJ] =  tmp

                Z = Z + tmp

            # update the weights
            for nodeJ in range(neighbors):
                self._adj[nodeI].weights[nodeJ] = hebbianWeights[nodeJ] / Z
                

                
                


    cdef double _learningFunction(self, int xi, int xj):
        """
        From Ito & Kaneko 2002
        """
        return 1 - 2 * (xi - xj)
