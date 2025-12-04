------------------------------------------------------------------------
--[[ Agent ]]--
-- Base class for reinforcement learning agents.
-- Provides the fundamental interface for agent-environment interaction.
-- Agents can observe states, select actions, receive rewards, and learn.
------------------------------------------------------------------------
local Agent, parent = torch.class('nn.Agent', 'nn.Module')

function Agent:__init()
   parent.__init(self)
   self.gamma = 0.99          -- discount factor
   self.epsilon = 1.0         -- exploration rate for epsilon-greedy
   self.epsilonMin = 0.01     -- minimum exploration rate
   self.epsilonDecay = 0.995  -- exploration decay rate
   self.nActions = 0          -- number of possible actions
   self.observationDim = 0    -- dimensionality of observations
   self.totalReward = 0       -- accumulated reward
   self.stepCount = 0         -- number of steps taken
   self.episodeCount = 0      -- number of episodes completed
   self.train = true          -- whether agent is in training mode
end

-- Initialize agent with observation and action dimensions
function Agent:setup(observationDim, nActions)
   self.observationDim = observationDim
   self.nActions = nActions
   return self
end

-- Select an action given the current observation
-- Returns action index (1-indexed for Lua compatibility)
function Agent:act(observation)
   -- Default implementation: random action
   return torch.random(1, self.nActions)
end

-- Process a transition (s, a, r, s', done)
-- This is called after each step in the environment
function Agent:observe(observation, action, reward, nextObservation, done)
   self.totalReward = self.totalReward + reward
   self.stepCount = self.stepCount + 1
   if done then
      self.episodeCount = self.episodeCount + 1
   end
end

-- Called at the start of each episode
function Agent:resetEpisode()
   self.totalReward = 0
end

-- Decay exploration rate
function Agent:decayEpsilon()
   if self.epsilon > self.epsilonMin then
      self.epsilon = self.epsilon * self.epsilonDecay
   end
end

-- Get current exploration rate
function Agent:getEpsilon()
   return self.epsilon
end

-- Set exploration rate
function Agent:setEpsilon(epsilon)
   self.epsilon = epsilon
   return self
end

-- Set discount factor
function Agent:setGamma(gamma)
   self.gamma = gamma
   return self
end

-- Get statistics about the agent's performance
function Agent:getStats()
   return {
      totalReward = self.totalReward,
      stepCount = self.stepCount,
      episodeCount = self.episodeCount,
      epsilon = self.epsilon
   }
end

-- Epsilon-greedy action selection helper
-- Returns true if should explore (random action), false if should exploit
function Agent:shouldExplore()
   return self.train and torch.uniform() < self.epsilon
end

-- Save agent state to file
function Agent:save(filename)
   local f = torch.DiskFile(filename, 'w')
   f:writeObject(self)
   f:close()
end

-- Load agent state from file
function Agent.load(filename)
   local f = torch.DiskFile(filename, 'r')
   local agent = f:readObject()
   f:close()
   return agent
end

function Agent:training()
   self.train = true
   parent.training(self)
end

function Agent:evaluate()
   self.train = false
   parent.evaluate(self)
end

function Agent:__tostring__()
   return torch.type(self) .. string.format(
      '(obs=%d, actions=%d, gamma=%.3f, epsilon=%.3f)',
      self.observationDim, self.nActions, self.gamma, self.epsilon)
end
