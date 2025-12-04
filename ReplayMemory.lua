------------------------------------------------------------------------
--[[ ReplayMemory ]]--
-- Experience replay buffer for reinforcement learning.
-- Stores transitions (state, action, reward, next_state, done) and
-- provides random sampling for training.
------------------------------------------------------------------------
local ReplayMemory = torch.class('nn.ReplayMemory')

function ReplayMemory:__init(capacity, observationDim)
   self.capacity = capacity or 10000
   self.observationDim = observationDim or 1
   self.position = 0
   self.size = 0

   -- Pre-allocate memory for efficiency
   if type(observationDim) == 'number' then
      self.observations = torch.Tensor(capacity, observationDim)
      self.nextObservations = torch.Tensor(capacity, observationDim)
   else
      -- Support multi-dimensional observations (e.g., images)
      local dims = {capacity}
      for i = 1, #observationDim do
         dims[#dims + 1] = observationDim[i]
      end
      self.observations = torch.Tensor(torch.LongStorage(dims))
      self.nextObservations = torch.Tensor(torch.LongStorage(dims))
   end

   self.actions = torch.LongTensor(capacity)
   self.rewards = torch.Tensor(capacity)
   self.dones = torch.ByteTensor(capacity)
end

-- Store a transition in the replay buffer
function ReplayMemory:push(observation, action, reward, nextObservation, done)
   self.position = self.position % self.capacity
   local idx = self.position + 1

   self.observations[idx]:copy(observation)
   self.actions[idx] = action
   self.rewards[idx] = reward
   self.nextObservations[idx]:copy(nextObservation)
   self.dones[idx] = done and 1 or 0

   self.position = self.position + 1
   self.size = math.min(self.size + 1, self.capacity)
end

-- Sample a random batch of transitions
function ReplayMemory:sample(batchSize)
   batchSize = math.min(batchSize, self.size)

   -- Generate random indices
   local indices = torch.LongTensor(batchSize)
   for i = 1, batchSize do
      indices[i] = torch.random(1, self.size)
   end

   -- Index observations based on their dimensionality
   local obs, nextObs
   if self.observations:nDimension() == 2 then
      obs = self.observations:index(1, indices)
      nextObs = self.nextObservations:index(1, indices)
   else
      obs = self.observations:index(1, indices)
      nextObs = self.nextObservations:index(1, indices)
   end

   return {
      observations = obs,
      actions = self.actions:index(1, indices),
      rewards = self.rewards:index(1, indices),
      nextObservations = nextObs,
      dones = self.dones:index(1, indices)
   }
end

-- Get current size of the buffer
function ReplayMemory:getSize()
   return self.size
end

-- Check if buffer has enough samples for a batch
function ReplayMemory:canSample(batchSize)
   return self.size >= batchSize
end

-- Clear the buffer
function ReplayMemory:clear()
   self.position = 0
   self.size = 0
end

-- Get all stored transitions (for debugging or analysis)
function ReplayMemory:getAll()
   if self.size == 0 then
      return nil
   end

   local indices = torch.range(1, self.size):long()
   return {
      observations = self.observations:index(1, indices),
      actions = self.actions:index(1, indices),
      rewards = self.rewards:index(1, indices),
      nextObservations = self.nextObservations:index(1, indices),
      dones = self.dones:index(1, indices)
   }
end

-- Type conversion
function ReplayMemory:type(type, tensorCache)
   if not type then
      return torch.type(self.observations)
   end

   tensorCache = tensorCache or {}
   self.observations = nn.utils.recursiveType(self.observations, type, tensorCache)
   self.nextObservations = nn.utils.recursiveType(self.nextObservations, type, tensorCache)
   self.rewards = nn.utils.recursiveType(self.rewards, type, tensorCache)
   return self
end

function ReplayMemory:float()
   return self:type('torch.FloatTensor')
end

function ReplayMemory:double()
   return self:type('torch.DoubleTensor')
end

function ReplayMemory:cuda()
   return self:type('torch.CudaTensor')
end

function ReplayMemory:__tostring__()
   return torch.type(self) .. string.format('(capacity=%d, size=%d)',
      self.capacity, self.size)
end
