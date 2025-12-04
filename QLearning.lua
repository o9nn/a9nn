------------------------------------------------------------------------
--[[ QLearning ]]--
-- Q-Learning module for value-based reinforcement learning.
-- Wraps a Q-network and provides methods for action selection,
-- target computation, and network updates.
--
-- Supports Double DQN and target network synchronization.
------------------------------------------------------------------------
local QLearning, parent = torch.class('nn.QLearning', 'nn.Module')

function QLearning:__init(qNetwork, nActions, config)
   parent.__init(self)

   config = config or {}

   self.qNetwork = qNetwork         -- online Q-network
   self.targetNetwork = nil         -- target Q-network (for stability)
   self.nActions = nActions or 1
   self.gamma = config.gamma or 0.99
   self.epsilon = config.epsilon or 1.0
   self.epsilonMin = config.epsilonMin or 0.01
   self.epsilonDecay = config.epsilonDecay or 0.995
   self.doubleDQN = config.doubleDQN or false  -- use Double DQN

   -- Internal state
   self.output = torch.Tensor()
   self.gradInput = torch.Tensor()
   self._qValues = torch.Tensor()
end

-- Initialize target network as a clone of the Q-network
function QLearning:initTargetNetwork()
   if self.qNetwork then
      self.targetNetwork = self.qNetwork:clone()
   end
   return self
end

-- Soft update target network: target = tau * online + (1-tau) * target
function QLearning:softUpdateTarget(tau)
   tau = tau or 0.001

   if not self.targetNetwork then
      self:initTargetNetwork()
      return self
   end

   local onlineParams = self.qNetwork:parameters()
   local targetParams = self.targetNetwork:parameters()

   if onlineParams and targetParams then
      for i = 1, #onlineParams do
         targetParams[i]:mul(1 - tau):add(tau, onlineParams[i])
      end
   end

   return self
end

-- Hard update target network: target = online
function QLearning:hardUpdateTarget()
   if self.qNetwork then
      self.targetNetwork = self.qNetwork:clone()
   end
   return self
end

-- Forward pass: compute Q-values for all actions
function QLearning:updateOutput(input)
   self.output = self.qNetwork:updateOutput(input)
   return self.output
end

-- Backward pass
function QLearning:updateGradInput(input, gradOutput)
   self.gradInput = self.qNetwork:updateGradInput(input, gradOutput)
   return self.gradInput
end

function QLearning:accGradParameters(input, gradOutput, scale)
   self.qNetwork:accGradParameters(input, gradOutput, scale)
end

-- Select action using epsilon-greedy policy
function QLearning:selectAction(observation)
   if self.train and torch.uniform() < self.epsilon then
      -- Random action
      return torch.random(1, self.nActions)
   else
      -- Greedy action
      local qValues = self:forward(observation)
      if qValues:nDimension() > 1 then
         qValues = qValues:squeeze()
      end
      local _, maxIdx = qValues:max(1)
      return maxIdx[1]
   end
end

-- Compute target Q-values for a batch of transitions
-- observations: current states [batch x obs_dim]
-- actions: actions taken [batch]
-- rewards: rewards received [batch]
-- nextObservations: next states [batch x obs_dim]
-- dones: terminal flags [batch] (1 if terminal)
function QLearning:computeTargets(observations, actions, rewards, nextObservations, dones)
   local batchSize = observations:size(1)

   -- Compute next Q-values using target network
   local targetNet = self.targetNetwork or self.qNetwork
   local nextQValues = targetNet:forward(nextObservations)

   local targets = torch.Tensor(batchSize)

   if self.doubleDQN and self.targetNetwork then
      -- Double DQN: use online network to select actions, target network to evaluate
      local onlineNextQ = self.qNetwork:forward(nextObservations)
      local _, bestActions = onlineNextQ:max(2)

      for i = 1, batchSize do
         local nextQ = dones[i] == 1 and 0 or nextQValues[i][bestActions[i][1]]
         targets[i] = rewards[i] + self.gamma * nextQ
      end
   else
      -- Standard DQN
      local maxNextQ, _ = nextQValues:max(2)

      for i = 1, batchSize do
         local nextQ = dones[i] == 1 and 0 or maxNextQ[i][1]
         targets[i] = rewards[i] + self.gamma * nextQ
      end
   end

   return targets
end

-- Compute TD loss for a batch (returns loss and gradient)
-- Returns: loss, gradOutput (gradient w.r.t. Q-values)
function QLearning:computeLoss(observations, actions, rewards, nextObservations, dones)
   local batchSize = observations:size(1)

   -- Forward pass
   local qValues = self:forward(observations)

   -- Compute targets
   local targets = self:computeTargets(observations, actions, rewards, nextObservations, dones)

   -- Compute loss (MSE) and gradients
   local loss = 0
   local gradOutput = torch.Tensor(qValues:size()):zero()

   for i = 1, batchSize do
      local action = actions[i]
      local td_error = qValues[i][action] - targets[i]
      loss = loss + td_error * td_error
      gradOutput[i][action] = 2 * td_error / batchSize
   end

   loss = loss / batchSize
   return loss, gradOutput
end

-- Decay epsilon
function QLearning:decayEpsilon()
   if self.epsilon > self.epsilonMin then
      self.epsilon = self.epsilon * self.epsilonDecay
   end
   return self
end

-- Get/set epsilon
function QLearning:getEpsilon()
   return self.epsilon
end

function QLearning:setEpsilon(epsilon)
   self.epsilon = epsilon
   return self
end

-- Enable/disable Double DQN
function QLearning:setDoubleDQN(enable)
   self.doubleDQN = enable
   return self
end

-- Get parameters (delegate to Q-network)
function QLearning:parameters()
   return self.qNetwork:parameters()
end

function QLearning:training()
   self.train = true
   self.qNetwork:training()
   if self.targetNetwork then
      self.targetNetwork:evaluate()  -- target is always in eval mode
   end
end

function QLearning:evaluate()
   self.train = false
   self.qNetwork:evaluate()
end

function QLearning:__tostring__()
   local tab = '  '
   local line = '\n'
   local str = torch.type(self) .. string.format(
      '(actions=%d, gamma=%.3f, epsilon=%.3f, doubleDQN=%s)',
      self.nActions, self.gamma, self.epsilon, tostring(self.doubleDQN)) .. ' {' .. line

   str = str .. tab .. '[qNetwork]: ' .. tostring(self.qNetwork):gsub(line, line .. tab) .. line

   if self.targetNetwork then
      str = str .. tab .. '[targetNetwork]: (initialized)' .. line
   end

   str = str .. '}'
   return str
end
