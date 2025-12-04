------------------------------------------------------------------------
--[[ OntogeneticKernel ]]--
-- Self-evolving kernel system for Agent-Neuro.
-- Implements B-Series Ontogenesis with differential operators
-- for self-optimization and genetic evolution.
--
-- Features:
-- - Kernel genome with genes and fitness
-- - Self-optimization through gradient-free evolution
-- - Mutation, crossover, and selection operations
-- - Population-based evolution with tournaments
------------------------------------------------------------------------
local OntogeneticKernel = torch.class('nn.OntogeneticKernel')

-- Gene types
local GENE_TYPES = {
   "coefficient",    -- Numeric parameter
   "activation",     -- Activation function selection
   "topology",       -- Network topology gene
   "behavior"        -- Behavioral parameter
}

-- KernelGene class (internal)
local KernelGene = {}
KernelGene.__index = KernelGene

function KernelGene.new(geneType, name, value, bounds)
   local self = setmetatable({}, KernelGene)
   self.type = geneType
   self.name = name
   self.value = value
   self.bounds = bounds or {0, 1}
   self.mutationRate = 0.1
   return self
end

function KernelGene:mutate(rate)
   rate = rate or self.mutationRate

   if torch.uniform() < rate then
      if self.type == "coefficient" then
         -- Gaussian mutation
         local delta = torch.randn(1)[1] * 0.1
         self.value = self.value + delta
         self.value = math.max(self.bounds[1], math.min(self.bounds[2], self.value))
      elseif self.type == "activation" then
         -- Random selection from options
         local options = {"ReLU", "Tanh", "Sigmoid", "ELU", "LeakyReLU"}
         self.value = options[torch.random(1, #options)]
      elseif self.type == "behavior" then
         -- Boolean flip
         self.value = not self.value
      end
      return true
   end
   return false
end

function KernelGene:clone()
   local copy = KernelGene.new(self.type, self.name, self.value, self.bounds)
   copy.mutationRate = self.mutationRate
   return copy
end

-- KernelGenome class (internal)
local KernelGenome = {}
KernelGenome.__index = KernelGenome

function KernelGenome.new(id, generation)
   local self = setmetatable({}, KernelGenome)
   self.id = id or "genome_" .. tostring(torch.random(1, 999999))
   self.generation = generation or 0
   self.genes = {}
   self.fitness = 0
   self.parentIds = {}
   self.created = os.time()
   return self
end

function KernelGenome:addGene(gene)
   self.genes[gene.name] = gene
end

function KernelGenome:getGene(name)
   return self.genes[name]
end

function KernelGenome:setFitness(fitness)
   self.fitness = fitness
end

function KernelGenome:mutate(rate)
   rate = rate or 0.15
   local mutations = {}
   for name, gene in pairs(self.genes) do
      if gene:mutate(rate) then
         table.insert(mutations, name)
      end
   end
   return mutations
end

function KernelGenome:crossover(other)
   local child = KernelGenome.new(nil, math.max(self.generation, other.generation) + 1)
   child.parentIds = {self.id, other.id}

   for name, gene in pairs(self.genes) do
      local otherGene = other.genes[name]
      if otherGene and torch.uniform() < 0.5 then
         child:addGene(otherGene:clone())
      else
         child:addGene(gene:clone())
      end
   end

   -- Add any genes only in other
   for name, gene in pairs(other.genes) do
      if not child.genes[name] then
         child:addGene(gene:clone())
      end
   end

   return child
end

function KernelGenome:clone()
   local copy = KernelGenome.new(nil, self.generation)
   copy.fitness = self.fitness
   copy.parentIds = {self.id}
   for name, gene in pairs(self.genes) do
      copy:addGene(gene:clone())
   end
   return copy
end

-- OntogeneticKernel main class
function OntogeneticKernel:__init(config)
   config = config or {}

   -- Initialize genome
   self.genome = KernelGenome.new(
      config.id or "neuro-consciousness-v" .. tostring(torch.random(1, 999)),
      config.generation or 0
   )

   -- Initialize default genes per spec
   self:_initializeDefaultGenes(config.personality)

   -- Evolution parameters
   self.mutationRate = config.mutationRate or 0.15
   self.crossoverRate = config.crossoverRate or 0.7
   self.eliteRatio = config.eliteRatio or 0.1

   -- Population for evolution
   self.population = {self.genome:clone()}
   self.populationSize = config.populationSize or 20

   -- Optimization history
   self.history = {
      generations = {},
      bestFitness = 0,
      totalOptimizations = 0
   }

   -- Differential operator state
   self.differentialState = {
      gradient = {},
      momentum = {},
      learningRate = 0.01
   }
end

-- Initialize default genes based on personality
function OntogeneticKernel:_initializeDefaultGenes(personality)
   -- Core cognitive coefficients
   self.genome:addGene(KernelGene.new("coefficient", "sarcasm_coefficient",
      personality and personality:get('sarcasm') or 0.90, {0, 1}))
   self.genome:addGene(KernelGene.new("coefficient", "chaos_coefficient",
      personality and personality:get('chaotic') or 0.95, {0, 1}))
   self.genome:addGene(KernelGene.new("coefficient", "playfulness_coefficient",
      personality and personality:get('playfulness') or 0.95, {0, 1}))
   self.genome:addGene(KernelGene.new("coefficient", "intelligence_coefficient",
      personality and personality:get('intelligence') or 0.95, {0.5, 1}))
   self.genome:addGene(KernelGene.new("coefficient", "empathy_coefficient",
      personality and personality:get('empathy') or 0.65, {0.5, 1}))

   -- Evolution parameters
   self.genome:addGene(KernelGene.new("coefficient", "exploration_rate", 0.3, {0, 0.5}))
   self.genome:addGene(KernelGene.new("coefficient", "attention_decay", 0.99, {0.9, 0.999}))

   -- Behavioral flags
   self.genome:addGene(KernelGene.new("behavior", "enable_self_optimization", true))
   self.genome:addGene(KernelGene.new("behavior", "enable_chaos_injection", true))

   -- Activation selection
   self.genome:addGene(KernelGene.new("activation", "default_activation", "ReLU"))
end

-- Self-optimization (per spec)
function OntogeneticKernel:selfOptimize(iterations)
   iterations = iterations or 10

   local startFitness = self.genome.fitness
   local startTime = os.time()

   for i = 1, iterations do
      -- Create offspring through mutation
      local offspring = self.genome:clone()
      local mutations = offspring:mutate(self.mutationRate)

      -- Evaluate fitness
      local fitness = self:evaluateFitness(offspring)
      offspring:setFitness(fitness)

      -- Selection: keep if better
      if fitness > self.genome.fitness then
         self.genome = offspring
         self.genome.generation = self.genome.generation + 1
      end
   end

   self.history.totalOptimizations = self.history.totalOptimizations + 1
   table.insert(self.history.generations, {
      generation = self.genome.generation,
      fitness = self.genome.fitness,
      improvement = self.genome.fitness - startFitness,
      timestamp = os.time()
   })

   if self.genome.fitness > self.history.bestFitness then
      self.history.bestFitness = self.genome.fitness
   end

   return self.genome
end

-- Evaluate fitness of a genome
function OntogeneticKernel:evaluateFitness(genome)
   local fitness = 0

   -- Base fitness from gene values (higher is better for most traits)
   for name, gene in pairs(genome.genes) do
      if gene.type == "coefficient" then
         -- Weight different genes differently
         if name == "intelligence_coefficient" then
            fitness = fitness + gene.value * 0.25
         elseif name == "chaos_coefficient" then
            fitness = fitness + gene.value * 0.15
         elseif name == "playfulness_coefficient" then
            fitness = fitness + gene.value * 0.15
         elseif name == "empathy_coefficient" then
            fitness = fitness + gene.value * 0.10
         elseif name == "sarcasm_coefficient" then
            fitness = fitness + gene.value * 0.10
         else
            fitness = fitness + gene.value * 0.05
         end
      end
   end

   -- Bonus for balance
   local chaosVal = genome:getGene("chaos_coefficient") and genome:getGene("chaos_coefficient").value or 0
   local empathyVal = genome:getGene("empathy_coefficient") and genome:getGene("empathy_coefficient").value or 0
   local balance = 1 - math.abs(chaosVal - 0.7)  -- Optimal chaos around 0.7
   fitness = fitness + balance * 0.1

   -- Ensure empathy floor
   if empathyVal >= 0.5 then
      fitness = fitness + 0.05
   else
      fitness = fitness - 0.2  -- Penalty for low empathy
   end

   return math.max(0, math.min(1, fitness))
end

-- Evolve population
function OntogeneticKernel:evolvePopulation(generations)
   generations = generations or 10

   -- Initialize population if needed
   while #self.population < self.populationSize do
      local newGenome = self.genome:clone()
      newGenome:mutate(self.mutationRate * 2)  -- Higher initial diversity
      newGenome:setFitness(self:evaluateFitness(newGenome))
      table.insert(self.population, newGenome)
   end

   for gen = 1, generations do
      -- Evaluate all
      for _, genome in ipairs(self.population) do
         genome:setFitness(self:evaluateFitness(genome))
      end

      -- Sort by fitness
      table.sort(self.population, function(a, b)
         return a.fitness > b.fitness
      end)

      -- Elite selection
      local eliteCount = math.max(1, math.floor(#self.population * self.eliteRatio))
      local newPopulation = {}
      for i = 1, eliteCount do
         table.insert(newPopulation, self.population[i]:clone())
      end

      -- Create offspring
      while #newPopulation < self.populationSize do
         -- Tournament selection for parents
         local parent1 = self:tournamentSelect(self.population, 3)
         local parent2 = self:tournamentSelect(self.population, 3)

         local child
         if torch.uniform() < self.crossoverRate then
            child = parent1:crossover(parent2)
         else
            child = parent1:clone()
         end

         child:mutate(self.mutationRate)
         child:setFitness(self:evaluateFitness(child))
         table.insert(newPopulation, child)
      end

      self.population = newPopulation
   end

   -- Update main genome to best
   table.sort(self.population, function(a, b)
      return a.fitness > b.fitness
   end)
   self.genome = self.population[1]:clone()

   return self.genome
end

-- Tournament selection
function OntogeneticKernel:tournamentSelect(population, tournamentSize)
   local candidates = {}
   for i = 1, tournamentSize do
      local idx = torch.random(1, #population)
      table.insert(candidates, population[idx])
   end

   table.sort(candidates, function(a, b)
      return a.fitness > b.fitness
   end)

   return candidates[1]
end

-- Crossover with another kernel (reproduce)
function OntogeneticKernel:reproduce(otherKernel)
   local childGenome = self.genome:crossover(otherKernel.genome)
   childGenome:mutate(self.mutationRate)
   childGenome:setFitness(self:evaluateFitness(childGenome))

   local childKernel = nn.OntogeneticKernel({
      id = childGenome.id,
      generation = childGenome.generation,
      mutationRate = (self.mutationRate + otherKernel.mutationRate) / 2
   })
   childKernel.genome = childGenome

   return childKernel
end

-- Apply differential operator for gradient-like updates
function OntogeneticKernel:applyDifferentialOperator(fitnessGradient)
   for name, grad in pairs(fitnessGradient) do
      local gene = self.genome:getGene(name)
      if gene and gene.type == "coefficient" then
         -- Momentum update
         self.differentialState.momentum[name] = self.differentialState.momentum[name] or 0
         self.differentialState.momentum[name] = 0.9 * self.differentialState.momentum[name] + 0.1 * grad

         -- Apply update
         gene.value = gene.value + self.differentialState.learningRate * self.differentialState.momentum[name]
         gene.value = math.max(gene.bounds[1], math.min(gene.bounds[2], gene.value))
      end
   end

   self.genome:setFitness(self:evaluateFitness(self.genome))
end

-- Get current gene values as table
function OntogeneticKernel:getGeneValues()
   local values = {}
   for name, gene in pairs(self.genome.genes) do
      values[name] = gene.value
   end
   return values
end

-- Set gene value
function OntogeneticKernel:setGene(name, value)
   local gene = self.genome:getGene(name)
   if gene then
      gene.value = value
      if gene.bounds then
         gene.value = math.max(gene.bounds[1], math.min(gene.bounds[2], gene.value))
      end
   end
end

-- Get fitness
function OntogeneticKernel:getFitness()
   return self.genome.fitness
end

-- Get generation
function OntogeneticKernel:getGeneration()
   return self.genome.generation
end

-- Get optimization history
function OntogeneticKernel:getHistory()
   return self.history
end

-- Export genome for serialization
function OntogeneticKernel:export()
   local data = {
      genome = {
         id = self.genome.id,
         generation = self.genome.generation,
         fitness = self.genome.fitness,
         genes = {}
      },
      config = {
         mutationRate = self.mutationRate,
         crossoverRate = self.crossoverRate,
         eliteRatio = self.eliteRatio
      },
      history = self.history
   }

   for name, gene in pairs(self.genome.genes) do
      data.genome.genes[name] = {
         type = gene.type,
         name = gene.name,
         value = gene.value,
         bounds = gene.bounds
      }
   end

   return data
end

function OntogeneticKernel:__tostring__()
   return torch.type(self) .. string.format(
      '(id=%s, gen=%d, fitness=%.3f)',
      self.genome.id, self.genome.generation, self.genome.fitness)
end
