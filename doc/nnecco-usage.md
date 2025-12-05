# NNECCO-A9NN Usage Examples

This document provides usage examples for the Neural Network Embodied Cognitive Coprocessor Orchestrator (NNECCO) cognitive architecture modules in a9nn.

## Overview

NNECCO-A9NN integrates five cognitive architecture components:

1. **EchoReservoirProcessor** - Echo State Network reservoir computing
2. **ConsciousnessLayerProcessor** - Multi-layer consciousness (L0-L3)
3. **EmotionProcessingUnit** - Discrete emotion channels with affect
4. **LLaMAOrchestrator** - Parallel LLaMA.cpp orchestration (1-9 instances)
5. **NNECCOAgent** - Main cognitive agent with EchoBeats loop

## Quick Start

### Using Individual Components

#### Echo State Reservoir

```lua
require 'nn'

-- Create reservoir processor
local reservoir = nn.EchoReservoirProcessor({
   reservoirSize = 847,    -- Number of reservoir neurons
   inputDim = 768,         -- Input dimension
   outputDim = 256,        -- Output dimension
   spectralRadius = 0.9,   -- Spectral radius for stability
   leakRate = 0.3          -- Leak rate for state update
})

-- Process input
local input = torch.randn(768)
local output = reservoir:updateOutput(input)

-- Adapt to different cognitive frames
reservoir:adaptParameters(0.8, 'chaos')     -- High arousal, chaos frame
reservoir:adaptParameters(0.5, 'strategy')  -- Medium arousal, strategy frame

-- Reset reservoir state
reservoir:reset()
```

#### Consciousness Layer Processor

```lua
require 'nn'

-- Create consciousness processor
local consciousness = nn.ConsciousnessLayerProcessor()

-- Process with different frames
local result1 = consciousness:processFrame('chaos', 'test input', nil)
print('Layer:', consciousness.currentLayer.level)  -- L1 for chaos

local result2 = consciousness:processFrame('strategy', 'analyze this', nil)
print('Layer:', consciousness.currentLayer.level)  -- L2 for strategy

-- Get consciousness shift messages
local msg = consciousness:getMessage()
if msg then
   print('Consciousness shift:', msg.type)
end
```

#### Emotion Processing Unit

```lua
require 'nn'

-- Create emotion unit
local emotion = nn.EmotionProcessingUnit()

-- Set emotion states
emotion:setEmotion('excited', 0.9, 0.8)  -- emotion, intensity, valence
print('Current emotion:', emotion.currentEmotion)
print('Arousal:', emotion.arousal)
print('Valence:', emotion.valence)

-- Get emotion vector
local emotionVec = emotion:getEmotionTensor()  -- 10-dimensional vector

-- Get reservoir modulation parameters
local modulation = emotion:modulateReservoir()
print('Input scale modifier:', modulation.input_scale_modifier)
print('Exploration bonus:', modulation.exploration_bonus)
```

#### LLaMA Orchestrator

```lua
require 'nn'

-- Create orchestrator with 4 parallel instances
local llama = nn.LLaMAOrchestrator({
   numInstances = 4,         -- 1-9 instances
   basePort = 8080,          -- Starting port (8080-8088)
   modelPath = 'models/llama-7b.gguf'
})

-- Initialize instances
llama:initialize()

-- Generate text (automatically load-balanced)
local result = llama:generate('Explain neural networks', {
   temperature = 0.7,
   max_tokens = 256
})

print('Response:', result.response)
print('Instance used:', result.instance_id)
print('Latency:', result.latency)

-- Check status
local status = llama:getStatus()
print('Active instances:', #status.instances)
print('Queue length:', status.queueLength)
print('Total requests:', status.stats.totalRequests)

-- Shutdown when done
llama:shutdown()
```

### Complete NNECCO Agent

```lua
require 'nn'

-- Create full NNECCO agent
local agent = nn.NNECCOAgent({
   llamaInstances = 4,       -- Parallel LLaMA instances
   reservoirSize = 847,      -- Reservoir neurons
   basePort = 8080,          -- LLaMA base port
   inputDim = 768,           -- Input dimension
   outputDim = 256           -- Output dimension
})

-- Process input through full cognitive pipeline
local input = "How can I optimize my neural network?"
local result = agent:process(input)

-- Access NNECCO-specific metadata
print('Reservoir size:', result.nnecco.reservoirSize)
print('Consciousness layer:', result.nnecco.consciousnessLayer.level)
print('Emotion state:', result.nnecco.emotionState)
print('LLaMA instances:', result.nnecco.llamaInstances)
print('EchoBeats phase:', result.nnecco.echobeatsPhase)

-- Run EchoBeats cognitive loop
for i = 1, 12 do
   agent:echobeat()  -- Runs one phase of the 12-step loop
end

-- Get hardware status
local hwStatus = agent:getHardwareStatus()
print('\nHardware Status:')
print('Reservoir state norm:', hwStatus.reservoir.stateNorm)
print('Consciousness layer:', hwStatus.consciousness.layer)
print('Current emotion:', hwStatus.emotion.current)
print('LLaMA instances active:', #hwStatus.llama.instances)

-- Shutdown
agent:shutdown()
```

## EchoBeats 12-Step Cognitive Loop

The NNECCO agent implements the EchoBeats cognitive loop with 12 phases:

1. **PERCEIVE** - Frame-aware perception
2. **ATTEND** - Attention spreading
3. **REPRESENT** - Reservoir state update
4. **REASON** - Multi-constraint optimization with LLaMA
5. **EMOTE** - Emotional state update
6. **INTEND** - Intention formation
7. **ACT** - Action execution
8. **REFLECT** - Consciousness layer processing
9. **LEARN** - Ontogenetic kernel evolution
10. **CONSOLIDATE** - AtomSpace memory storage
11. **PRUNE** - Memory pruning
12. **REST** - State reset

Each phase can be executed individually:

```lua
local agent = nn.NNECCOAgent()

-- Run one phase at a time
agent:echobeat()  -- Phase 1: PERCEIVE
agent:echobeat()  -- Phase 2: ATTEND
agent:echobeat()  -- Phase 3: REPRESENT
-- ... continues through all 12 phases, then wraps back to 1
```

## Integration with Existing a9nn Components

NNECCO agent inherits from NeuroAgent, which provides:

- **Personality system** (nn.Personality)
- **AtomSpace** knowledge graphs (nn.AtomSpace)
- **Ontogenetic kernel** self-evolution (nn.OntogeneticKernel)
- **Multi-agent orchestration** (nn.CognitiveAgent)

```lua
local agent = nn.NNECCOAgent({
   personality = nn.Personality({
      playfulness = 0.8,
      intelligence = 0.9,
      chaotic = 0.7,
      empathy = 0.6
   })
})

-- Access inherited components
print('Personality:', agent.personality:get('playfulness'))

-- Use AtomSpace
agent.atomSpace:addNode('ConceptNode', 'MyIdea', {0.9, 0.8}, 0.7)

-- Spawn subordinate agents
local sub = agent:spawnSubordinate({
   role = 'pattern_analyzer',
   personalityOverrides = {intelligence = 0.95}
})
```

## Advanced Configuration

### Custom Reservoir Configuration

```lua
local agent = nn.NNECCOAgent({
   reservoirSize = 1200,       -- Larger reservoir
   inputDim = 1024,            -- Larger input
   outputDim = 512,            -- Larger output
   personality = nn.Personality({
      cognitive_power = 0.98    -- Increase cognitive capacity
   })
})
```

### Multiple Parallel Configurations

```lua
-- Maximum parallelism (9 instances)
local maxAgent = nn.NNECCOAgent({
   llamaInstances = 9,
   basePort = 8080
})

-- Minimal setup (1 instance)
local minAgent = nn.NNECCOAgent({
   llamaInstances = 1,
   basePort = 8080
})
```

## Testing

Run the NNECCO test suite:

```bash
th -lnn test/test_nnecco.lua
```

Or test specific components:

```lua
require 'nn'

-- Test EchoReservoirProcessor
local esrp = nn.EchoReservoirProcessor()
assert(esrp.reservoirSize == 847, 'Reservoir size should be 847')

-- Test ConsciousnessLayerProcessor
local clp = nn.ConsciousnessLayerProcessor()
assert(clp.currentLayer.level == 1, 'Should start at L1')

-- Test EmotionProcessingUnit
local epu = nn.EmotionProcessingUnit()
epu:setEmotion('happy', 0.8)
assert(epu.currentEmotion == 'happy', 'Emotion should be set')

print('All tests passed!')
```

## Performance Considerations

### Resource Usage

| Component | CPU | Memory |
|-----------|-----|--------|
| EchoReservoir (847 neurons) | 5-10% | ~100MB |
| ConsciousnessLayer | <1% | ~10MB |
| EmotionUnit | <1% | ~5MB |
| LLaMA instance (each) | 15-20% | 2-4GB |
| Full agent (4 LLaMA) | 70-95% | 9-17GB |

### Latency Targets

| Operation | Target | Typical |
|-----------|--------|---------|
| Reservoir forward | <2ms | 1.2ms |
| Consciousness message | <5ms | 3.5ms |
| Emotion update | <1ms | 0.5ms |
| LLaMA generation | <500ms | 350ms |
| Full EchoBeats cycle | <100ms | 75ms |

## Troubleshooting

### LLaMA instances not starting

```lua
local llama = nn.LLaMAOrchestrator({numInstances = 4})
llama:initialize()

-- Check if instances are active
local status = llama:getStatus()
for i, inst in ipairs(status.instances) do
   if not inst.active then
      print('Instance', i, 'on port', inst.port, 'is not active')
   end
end
```

### Reservoir state explosion

```lua
-- Monitor reservoir state norm
local agent = nn.NNECCOAgent()
agent:process(input)

local hwStatus = agent:getHardwareStatus()
if hwStatus.reservoir.stateNorm > 100 then
   print('Warning: Reservoir state norm is high')
   agent.reservoir:reset()  -- Reset if needed
end
```

## See Also

- **[a9nn.md](.github/agents/a9nn.md)** - A9NN framework overview
- **[nnecco-a9nn.md](.github/agents/nnecco-a9nn.md)** - Full NNECCO specification
- **[agent-neuro.md](.github/agents/agent-neuro.md)** - Neuro-Sama personality framework
- **[deep-tree-echo.md](.github/agents/deep-tree-echo.md)** - Deep Tree Echo architecture

---

**NNECCO-A9NN** - *Where reservoir computing meets consciousness, emotion flows through tensors, and parallel inference orchestrates cognition.*
